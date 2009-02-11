package RT::Action::ExtractCustomFieldValues;
require RT::Action::Generic;

use strict;
use warnings;

use base qw(RT::Action::Generic);

our $VERSION = 2.0;

sub Describe {
    my $self = shift;
    return ( ref $self );
}

sub Prepare {
    return (1);
}

sub Commit {
    my $self            = shift;
    my $Transaction     = $self->TransactionObj;
    my $FirstAttachment = $Transaction->Attachments->First;
    unless ($FirstAttachment) { return 1; }

    my $Ticket    = $self->TicketObj;
    my $Content   = $self->TemplateObj->Content;
    my $Queue     = $Ticket->QueueObj->Id;
    my $Separator = '\|';

    my @lines = split( /[\n\r]+/, $Content );
    for (@lines) {
        chomp;
        next if (/^#/);
        next if (/^\s*$/);
        if (/^Separator=(.*)$/) {
            $Separator = $1;
            next;
        }
        my ( $CustomFieldName, $InspectField, $MatchString, $PostEdit,
            $Options )
            = split(/$Separator/);

        if ( $Options =~ /\*/ ) {
            ProcessWildCard(
                Field       => $InspectField,
                Match       => $MatchString,
                PostEdit    => $PostEdit,
                Attachment  => $FirstAttachment,
                Queue       => $Queue,
                Ticket      => $Ticket,
                Transaction => $Transaction,
                Options     => $Options,
            );
            next;
        }

        my $cf;
        if ($CustomFieldName) {
            $cf = LoadCF( Field => $CustomFieldName, Queue => $Queue );
        }

        my $match = FindMatch(
            Field           => $InspectField,
            Match           => $MatchString,
            FirstAttachment => $FirstAttachment,
        );

        my %processing_args = (
            CustomField => $cf,
            Match       => $match,

            Ticket      => $Ticket,
            Transaction => $Transaction,
            Attachment  => $FirstAttachment,

            PostEdit => $PostEdit,
            Options  => $Options,
        );

        if ($cf) {
            ProcessCF(%processing_args);
        } else {
            ProcessMatch(%processing_args);
        }
    }
    return (1);
}

sub LoadCF {
    my %args            = @_;
    my $CustomFieldName = $args{Field};
    my $Queue           = $args{Queue};

    $RT::Logger->debug("load cf $CustomFieldName");
    my $cf = RT::CustomField->new($RT::SystemUser);
    $cf->LoadByNameAndQueue( Name => $CustomFieldName, Queue => $Queue );
    $cf->LoadByNameAndQueue( Name => $CustomFieldName, Queue => 0 )
        unless $cf->id;

    if ( $cf->id ) {
        $RT::Logger->debug( "load cf done: " . $cf->id );
    } elsif ( not $args{Quiet} ) {
        $RT::Logger->error("couldn't load cf $CustomFieldName");
    }

    return $cf;
}

sub ProcessWildCard {
    my %args = @_;

    my $content
        = lc $args{Field} eq "body"
        ? $args{Attachment}->Content
        : $args{Attachment}->GetHeader( $args{Field} );
    while ( $content =~ /$args{Match}/mg ) {
        my ( $cf, $value ) = ( $1, $2 );
        $cf = LoadCF( Field => $cf, Queue => $args{Queue}, Quiet => 1 );
        next unless $cf;
        ProcessCF(
            %args,
            CustomField => $cf,
            Match       => $value
        );
    }
}

sub FindMatch {
    my %args = @_;

    my $match = '';
    if ( $args{Field} =~ /^body$/i ) {
        $RT::Logger->debug("look for match in Body");
        if (   $args{FirstAttachment}->Content
            && $args{FirstAttachment}->Content =~ /$args{Match}/m )
        {
            $match = $1 || $&;
            $RT::Logger->debug("matched value: $match");
        }
    } else {
        $RT::Logger->debug("look for match in Header $args{Field}");
        if ( $args{FirstAttachment}->GetHeader("$args{Field}")
            =~ /$args{Match}/ )
        {
            $match = $1 || $&;
            $RT::Logger->debug("matched value: $match");
        }
    }

    return $match;
}

sub ProcessCF {
    my %args = @_;

    my @values = ();
    if ( $args{CustomField}->SingleValue() ) {
        push @values, $args{Match};
    } else {
        @values = split( ',', $args{Match} );
    }

    foreach my $value ( grep defined && length, @values ) {
        if ( $args{PostEdit} ) {
            local $@;
            eval( $args{PostEdit} );
            $RT::Logger->error("$@") if $@;
            $RT::Logger->debug("transformed ($args{PostEdit}) value: $value");
        }
        next unless defined $value && length $value;

        $RT::Logger->debug("found value for cf: $value");
        my ( $id, $msg ) = $args{Ticket}->AddCustomFieldValue(
            Field             => $args{CustomField},
            Value             => $value,
            RecordTransaction => $args{Options} =~ /q/ ? 0 : 1
        );
        $RT::Logger->info( "CustomFieldValue ("
                . $args{CustomField}->Name
                . ",$value) added: $id $msg" );
    }
}

sub ProcessMatch {
    my %args            = @_;
    my $Ticket          = $args{Ticket};
    my $Transaction     = $args{Transaction};
    my $FirstAttachment = $args{Attachment};

    if ( $args{Match} && $args{PostEdit} ) {
        local $_ = $args{Match};    # backwards compatibility
        local $@;
        eval( $args{PostEdit} );
        $RT::Logger->error("$@") if $@;
        $RT::Logger->debug("ran code $args{PostEdit} $@");
    }
}

1;
