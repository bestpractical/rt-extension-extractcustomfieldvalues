use inc::Module::Install;
RTx('RT-Extension-ExtractCustomFieldValues');

repository('https://github.com/bestpractical/rt-extension-extractcustomfieldvalues');

sign;
&WriteAll;
