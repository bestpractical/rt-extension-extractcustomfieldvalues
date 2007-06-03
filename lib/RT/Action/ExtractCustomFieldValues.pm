package RT::Action::ExtractCustomFieldValues;
require RT::Action::Generic;

use strict;
use warnings;

use base qw(RT::Action::Generic);

our $VERSION = 1.3;

sub Describe  {
  my $self = shift;
  return (ref $self );
}

sub Prepare {
  return (1);
}

sub Commit {
    my $self = shift;
    my $Transaction = $self->TransactionObj;
    my $FirstAttachment = $Transaction->Attachments->First;
    unless ( $FirstAttachment ) { return 1; }

    my $Ticket = $self->TicketObj;
    my $Content = $self->TemplateObj->Content;
    my $Queue = $Ticket->QueueObj->Id;
    my $Separator = '\|';

    my @lines = split(/[\n\r]+/,$Content);
    for (@lines) {
        chomp;
        next if (/^#/);
        next if (/^\s*$/);
        if (/^Separator=(.*)$/) {
            $Separator=$1;
            next;
        }
        my ($CustomFieldName,$InspectField,$MatchString,$PostEdit,$Options) = split(/$Separator/);

        my $cf;
        if ($CustomFieldName) {
            $cf = LoadCF( Field => $CustomFieldName, Queue => $Queue );
        }

        my $match = FindMatch( Field           => $InspectField, 
                               Match           => $MatchString,
                               FirstAttachment => $FirstAttachment );

        my %processing_args = (
            CustomField => $cf,
            Match       => $match,

            Ticket      => $Ticket,
            Transaction => $Transaction,
            Attachment  => $FirstAttachment,

            PostEdit    => $PostEdit,
            Options     => $Options,
        );

        if ( $cf ) {
            ProcessCF( %processing_args );
        } else {
            ProcessMatch( %processing_args );
        }
    }
    return(1);
}

sub LoadCF {
    my %args = @_;
    my $CustomFieldName = $args{Field};
    my $Queue = $args{Queue};

    $RT::Logger->debug("load cf $CustomFieldName");
    my $cf = new RT::CustomField($RT::SystemUser);
    my ($id,$msg) = $cf->LoadByNameAndQueue (Name=>"$CustomFieldName", Queue=>$Queue);
    if (! $id) {
      ($id,$msg) = $cf->LoadByNameAndQueue (Name=>"$CustomFieldName", Queue=>0);
    }
    $RT::Logger->debug("load cf done: $id $msg");

    return $cf;

}

sub FindMatch {
    my %args = @_;

    my $match = '';
    if ($args{Field} =~ /^body$/i) {
        $RT::Logger->debug("look for match in Body");
        if ($args{FirstAttachment}->Content =~ /$args{Match}/m) {
            $match = $1||$&;
            $RT::Logger->debug("matched value: $match");
        }
    } else {
        $RT::Logger->debug("look for match in Header $args{Field}");
        if ($args{FirstAttachment}->GetHeader("$args{Field}") =~ /$args{Match}/) {
            $match = $1||$&;
            $RT::Logger->debug("matched value: $match");
        }
    }

    return $match;
}

sub ProcessCF {
    my %args = @_;

    my @values=();
    if ($args{CustomField}->SingleValue()) {
        push @values, $args{Match};
    } else {
        @values = split(',', $args{Match});
    }

    foreach my $value (@values) {
        if ($value && $args{PostEdit}) {
            local $_ = $value; # backwards compatibility
            eval($args{PostEdit});
            $RT::Logger->debug("transformed ($args{PostEdit}) value: $value");
        }
        if ($value) {
            $RT::Logger->debug("found value for cf: $value");
            my ($id,$msg) = $args{Ticket}->AddCustomFieldValue
                                             ( Field => $args{CustomField}, 
                                               Value => $value , 
                                               RecordTransaction => $args{Options} =~ /q/ ? 0 : 1);
            $RT::Logger->info("CustomFieldValue (".$args{CustomField}->Name.",$value) added: $id $msg");
        }
    }
}

sub ProcessMatch {
    my %args = @_;
    my $Ticket = $args{Ticket};
    my $Transaction = $args{Transaction};
    my $FirstAttachment = $args{Attachment};

    if ($args{Match} && $args{PostEdit}) {
        local $_ = $args{Match}; # backwards compatibility
        eval($args{PostEdit});
        $RT::Logger->debug("ran code $args{PostEdit} $@");
    }
}

1;
