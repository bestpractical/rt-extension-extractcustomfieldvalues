package RT::Action::ExtractCustomFieldValuesWithCodeInTemplate;
use strict;
use warnings;

use base qw(RT::Action::ExtractCustomFieldValues);

sub TemplateContent {
    my $self = shift;
    my $content = $self->TemplateObj->Content;


    return $content;
}

1;

