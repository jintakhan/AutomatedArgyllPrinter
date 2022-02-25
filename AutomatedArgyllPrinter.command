# Automated ArgyllCMS script for calibrating printers
# Uses ArgyllCMS v2.3.0, the latest version at the time of writing
# Script by Jintak Han
# Based on instructions at https://rawtherapee.com/mirror/dcamprof/argyll-print.html

#!/bin/bash

#dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
cd "$(dirname "$0")"

if [ ! -d "./Argyll_V2.3.0" ]
then
  echo 'ArgyllCMS not found in the working directory. Downloading...'
  curl 'https://www.argyllcms.com/Argyll_V2.3.0_osx10.6_x86_64_bin.tgz' -o ArgyllCMS.tgz
  tar xf ArgyllCMS.tgz
  rm ArgyllCMS.tgz
fi

export PATH=Argyll_V2.3.0/bin:$PATH

echo 'Enter a name for this profile.'
echo 'This is what you will see in Photoshop.'
echo 'Having a date in the name is highly recommended.'
read -r -p 'Enter a name: ' desc
echo 'Enter a desired filename for this profile.'
echo 'If your filename is foobar, your profile will be named foobar.icc.'
read -r -p 'Enter a filename: ' name

echo 'Creating a test chart...'
echo 'Please choose a spectrophotometer model.'
echo '1: i1Pro (Default)'
echo '2: i1Pro3+'
echo '3: ColorMunki'
echo '4: DTP20'
echo '5: DTP22'
echo '6: DTP41'
echo '7: DTP51'
echo '8: SpectroScan'
read -r answer
case $answer in
  1) inst=i1 ;;
  2) inst=3p ;;
  3) inst=CM ;;
  4) inst=20 ;;
  5) inst=22 ;;
  6) inst=41 ;;
  7) inst=51 ;;
  8) inst=SS ;;
  *)
    inst=i1
    echo 'No valid selection made. Using default instrument...'
    ;;
esac
echo 'How many patches do you want to scan?'
echo 'The default value is 400 and the recommended range is 200-1200.'
read -r patch 
if [ "$patch" > 0 ]; then
  :
else
    echo 'Invalid entry. Defaulting to 400 patches...'
    patch=400
fi

targen -v -d2 -G -g32 -f${patch} ${name}

printtarg -v -i${inst} -h -R1 -T300 -p Letter ${name}
echo 'Test chart '${desc}'.tif created.'
echo 'Please print the test chart using the option "Print as Color Target" on ColorSync Utility.'
open .
open /System/Applications/Utilities/ColorSync\ Utility.app
read -p 'Press enter to continue...'

echo 'Please connect the spectrophotometer.'
read -p 'Press enter to continue...'

chartread -v -H -T0.4 ${name}
colprof -v -qh -S /Library/Application\ Support/Adobe/Color/Profiles/Recommended/AdobeRGB1998.icc -cmt -dpp -D"${desc}" ${name}

echo 'Profile created. Performing sanity check...'
profcheck -k ${name}.ti3 ${name}.icc
echo 'Sanity check complete.'

read -r -p 'Do any of the profile error values exceed 2.0? [y/n] ' response
while [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
do
  echo 'Error above acceptable value. Remeasuring...'
  chartread -v -H -T0.4 ${name}
  colprof -v -qh -S /Library/Application\ Support/Adobe/Color/Profiles/Recommended/AdobeRGB1998.icc -cmt -dpp -D"${desc}" ${name}
  echo 'Profile created. Performing sanity check...'
  profcheck -k ${name}.ti3 ${name}.icc
  echo 'Sanity check complete.'
  read -r -p 'Do any of the profile error values exceed 2.0? [y/n] ' response
done

echo 'Installing measured ICC profile...'
cp ${name}.icc ~/Library/ColorSync/Profiles/
echo 'Finished. '${name}'.icc was installed to the directory ~/Library/ColorSync/Profiles'
echo 'Please restart any color-managed applications before using this profile.'
echo 'To print with this profile in a color-managed workflow, select "'${desc}'" in the profile selection menu.'
