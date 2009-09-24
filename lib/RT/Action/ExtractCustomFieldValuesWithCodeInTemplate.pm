package RT::Action::ExtractCustomFieldValuesWithCodeInTemplate;
use strict;
use warnings;

use base qw(RT::Action::ExtractCustomFieldValues);

sub TemplateContent {
    my $self = shift;

    my $content = $self->TemplateObj->Content;

    my $template = Text::Template->new(TYPE => 'STRING', SOURCE => $content);
    my $new_content = $template->fill_in;

    return $new_content;
}

1;

