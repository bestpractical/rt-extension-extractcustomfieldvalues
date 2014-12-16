use warnings;
use strict;

package RT::Extension::ExtractCustomFieldValues;

=head1 NAME

RT::Extension::ExtractCustomFieldValues - extract CF values from email headers or body

=cut

our $VERSION = '3.12';

1;

=head1 DESCRIPTION

ExtractCustomFieldValues provides an "ExtractCustomFieldValues" scrip
action, which can be used to scan incoming emails to set values of
custom fields.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::ExtractCustomFieldValues');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::ExtractCustomFieldValues));

or add C<RT::Extension::ExtractCustomFieldValues> to your existing C<@Plugins> line.

=item Restart your webserver

=back

=head1 USAGE

To use the ScripAction, create a Template and a Scrip in RT.
Your new Scrip should use a ScripAction of 'Extract Custom Field Values'.
The Template consists of the lines which control the scanner. All
non-comment lines are of the following format:

    <cf-name>|<Headername>|<MatchString>|<Postcmd>|<Options>

where:

=over 4

=item I<cf-name>

The name of a custom field (must be created in RT).  If this field is
blank, the match will be run and Postcmd will be executed, but no custom
field will be updated. Use this if you need to execute other RT code
based on your match.

=item I<Headername>

Either a Name of an email header, "body" to scan the body
of the email or "headers" to search all of the headers.

=item I<MatchString>

A regular expression to find a match in the header or body.  If the
MatchString matches a comma separated list and the CF is a multi-value
CF then each item in the list is added as a separate value.

=item I<Postcmd>

Perl code to be evaluated on C<$value>, where C<$value> is either $1 or
full match text from the match performed with <MatchString>

=item I<Options>

A string of letters which may control some aspects.  Possible options
include:

=over 4

=item I<q> - (quiet)

Don't record a transaction when adding the custom field value

=item I<*> - (wildcard)

The MatchString regex should contain _two_ capturing groups, the first
of which is the CF name, the second of which is the value.  If this
option is given, the <cf-name> field is ignored.  (Supercedes '+'.)

=item I<+> - (multiple)

The MatchString regex will be applied with the /g option and all
matching values will be added to the CF, which should probably be a
multi-value CF for best results.  (Superceded by '*'.)

=back

=back

=head2 Separator

You can change the separator string (initially "\|") during the
template with:

    Separator=<anyregexp>

Changing the separator may be necessary, if you want to use a "|" in
one of the patterns in the controlling lines.

=head2 Example and further reading

An example template with some further examples is installed during
C<make initdb>. See the CustomFieldScannerExample template for examples
and further documentation.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

Based on code by Dirk Pape E<lt>pape@inf.fu-berlin.deE<gt>.

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-ExtractCustomFieldValues@rt.cpan.org|mailto:bug-RT-Extension-ExtractCustomFieldValues@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ExtractCustomFieldValues>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2007-2014 by Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
