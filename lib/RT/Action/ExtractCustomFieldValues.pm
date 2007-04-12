package RT::Action::ExtractCustomFieldValues;
require RT::Action::Generic;

use strict;
use vars qw/@ISA/;
@ISA=qw(RT::Action::Generic);

our $VERSION = 1.2;

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
    $RT::Logger->debug("load cf $CustomFieldName");
    my $cf = new RT::CustomField($RT::SystemUser);
    my ($id,$msg) = $cf->LoadByNameAndQueue (Name=>"$CustomFieldName", Queue=>$Queue);
    if (! $id) {
      ($id,$msg) = $cf->LoadByNameAndQueue (Name=>"$CustomFieldName", Queue=>0);
    }
    $RT::Logger->debug("load cf done: $id $msg");
    if ($id) {
      my $found = 0;
      if ($InspectField =~ /^body$/i) {
        $RT::Logger->debug("look for cf in Body");
        $found = ($FirstAttachment->Content =~ /$MatchString/m);
        if ($1) { $_ = $1; } else { $_ = $&; }
      } else {
        $RT::Logger->debug("look for cf in Header $InspectField");
        $found = ($FirstAttachment->GetHeader("$InspectField") =~ /$MatchString/);
        if ($1) { $_ = $1; } else { $_ = $&; }
      }
      if ($found) {
        $RT::Logger->debug("matched value: $_");
      } else {
        $_ = "";
      }

      my @values=();
      if ( $cf->SingleValue()) {
         push @values, $_;
      } else {
         @values = split(',', $_);
      }
      
      foreach (@values) {
         if ($_ && $PostEdit) {
            eval ($PostEdit);
            $RT::Logger->debug("transformed ($PostEdit) value: $_");
         }
         if ($_) {
            $RT::Logger->debug("found value for cf: $_");
            ($id,$msg) = $Ticket->AddCustomFieldValue
                (Field => $cf, Value => $_, RecordTransaction => $Options =~ /q/ ? 0 : 1);
            $RT::Logger->info("CustomFieldValue ($CustomFieldName,$_) added: $id $msg");
         }
      }
    }
  }
  return(1);
}

1;
