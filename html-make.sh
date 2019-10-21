#!/bin/sh

componentsPath=$1
templatesPath=$2
finalsPath=$3

echo "picking up component from $componentsPath..."
componentName=$(ls $componentsPath)

echo "reading content of $componentsPath$componentName into memory..."
componentContent=$(tr '\n' ' ' <$componentsPath$componentName)

echo "picking up template from $templatesPath..."
templateName=$(ls $templatesPath)

echo "replacing component declarations in $templatesPath$templateName..."
sed 's|\[\[[a-zA-Z\-]\]\]|'"$componentContent"'|' <$templatesPath$templateName >$finalsPath$templateName

echo "done."