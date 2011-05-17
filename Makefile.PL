use inc::Module::Install;
RTx('RT-Extension-ExtractCustomFieldValues');
all_from('lib/RT/Extension/ExtractCustomFieldValues.pm');
readme_from('lib/RT/Extension/ExtractCustomFieldValues.pm');
sign;
&WriteAll;
