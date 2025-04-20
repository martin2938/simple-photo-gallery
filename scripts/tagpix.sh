#! /bin/bash

###########################################################################
# script to quickly rate and descibe images
# start with a directory: ./tagpix.sh images/
#
# actions:
# 1-5: set rating of current image
# 6: edit description
# 7: edit section
# 8: rotate left
# 9: rotate right
###########################################################################

FEH=/usr/bin/feh
EXIF="/usr/bin/exiftool"
EXIF_PARAMS="-overwrite_original_in_place -preserve"
ROTATE_LEFT="exiftran -i -p -2 %f"
ROTATE_RIGHT="exiftran -i -p -9 %f"
VS_CODE="code --wait --new-window"

if [ "$#" -eq 1 ]; then
	if ! [ -d "$1" ]; then
		echo "$0 IMAGE_DIR"
		exit 1
	fi
	$FEH --verbose --edit --hide-pointer -F --draw-tinted --font "yudit/16" --info "$0 %F print_meta %u/%l" \
		--action1 "$EXIF $EXIF_PARAMS -rating=1 %f" \
		--action2 "$EXIF $EXIF_PARAMS -rating=2 %f" \
		--action3 "$EXIF $EXIF_PARAMS -rating=3 %f" \
		--action4 "$EXIF $EXIF_PARAMS -rating=4 %f" \
		--action5 "$EXIF $EXIF_PARAMS -rating=5 %f" \
		--action6 "$0 %f edit_description" \
		--action7 "$0 %f edit_section" \
		--action8 ";$ROTATE_LEFT" \
		--action9 ";$ROTATE_RIGHT" \
		$1
elif [ "$#" -ge 2 ]; then
	description=$($EXIF -j -Exif:ImageDescription $1 | jq -r '.[0].ImageDescription' | grep -v null)
	section=$($EXIF -j -Artist $1 | jq -r '.[0].Artist' | grep -v null)
	if [ "$2" = "print_meta" ]; then
		size=$($EXIF -j -ImageSize $1 | jq -r '.[0].ImageSize')
		rating=$($EXIF -j -Rating $1 | jq -r '.[0].Rating')
		filename=$(basename $1)
		echo "$description"
		if ! [ -z "$section" ]; then
			echo section: $section
		fi
		echo "$rating | $3 | $size"
	elif [ "$2" = "edit_description" ]; then  # TODO: use zenity when multi-line text-boxes are supported: https://gitlab.gnome.org/GNOME/zenity/-/issues/102
		tmpfile=$(mktemp)
		echo "$description" > $tmpfile
		$VS_CODE $tmpfile
		new_description=$(cat $tmpfile)
		rm $tmpfile
		if [ "$new_description" != "$description" ]; then
			$EXIF $EXIF_PARAMS -Exif:ImageDescription="$new_description" $1
		fi
	elif [ "$2" = "edit_section" ]; then
		new_section=$(zenity --title 'Section' --entry --entry-text="$section")
		if [ $? = 0 ]; then
			$EXIF $EXIF_PARAMS -Artist="$new_section" $1
		fi
	fi
	exit 0
fi
