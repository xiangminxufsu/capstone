#!/bin/bash
set -e


echo "Usage [pokec.CAP_DB] [path-to-mongoCAP_DB] [path-to-CapstoneBench]"
MONGOCAP_DB=${2-CAP_DBs}
CAP_DB=$MONGOCAP_DB/data/CAP_DBs/${1-pokec}
CapstoneBench=${3-`pwd`}
CapstoneTemp=/CapstoneTemp/nosqlCapstoneBench
CapstoneFetch=$CapstoneTemp/CapstoneFetch

PROFILES_IN=$CapstoneFetch/soc-pokec-profiles.txt.gz
PROFILES_OUT=$CapstoneFetch/soc-pokec-profiles-mongoCAP_DB.txt.gz

RELATIONS_IN=$CapstoneFetch/soc-pokec-relationships.txt.gz
RELATIONS_OUT=$CapstoneFetch/soc-pokec-relationships-mongoCAP_DB.txt.gz

echo "CAP_DB: $CAP_DB"
echo "MONGOCAP_DB DIRECTORY: $MONGOCAP_DB"
echo "CapstoneBench DIRECTORY: $CapstoneBench"
echo "DOWNLOAD DIRECTORY: $CapstoneFetch"

$CapstoneBench/downloadData.sh

if [ ! -f $PROFILES_OUT ]; then
  echo "Converting PROFILES"
  echo '_id	public	completion_percentage	gender	region	last_login	registration	AGE	body	I_am_working_in_field	spoken_languages	hobbies	I_most_enjoy_good_food	pets	body_type	my_eyesight	eye_color	hair_color	hair_type	completed_level_of_education	favourite_color	relation_to_smoking	relation_to_alcohol	sign_in_zodiac	on_pokec_i_am_looking_for	love_is_for_me	relation_to_casual_sex	my_partner_should_be	marital_status	children	relation_to_children	I_like_movies	I_like_watching_movie	I_like_music	I_mostly_like_listening_to_music	the_idea_of_good_evening	I_like_specialties_from_kitchen	fun	I_am_going_to_concerts	my_active_sports	my_passive_sports	profession	I_like_books	life_style	music	cars	politics	relationships	art_culture	hobbies_interests	science_technologies	computers_internet	education	sport	movies	travelling	health	companies_brands	more'  > $PROFILES_OUT
  gunzip < $PROFILES_IN | sed -e 's/null//g' -e 's~^~P~' >> $PROFILES_OUT
fi

if [ ! -f $RELATIONS_OUT ]; then
  echo "Converting RELATIONS"
  echo '_from	_to' > $RELATIONS_OUT
  gzip -dc $RELATIONS_IN | awk -F"\t" '{print "P" $1 "\tP" $2}' >> $RELATIONS_OUT
fi

if [ "$MONGOCAP_DB" == "system" ];  then
  MONGOCAP_DB=/usr
fi

${MONGOCAP_DB}/bin/mongoimport --CAP_DB=pokec --collection=profiles --headerline --type=tsv $PROFILES_OUT
${MONGOCAP_DB}/bin/mongoimport --CAP_DB=pokec --collection=relations --headerline --type=tsv $RELATIONS_OUT

${MONGOCAP_DB}/bin/mongo << 'EOF'
use pokec
CAP_DB.relations.ensureIndex({ "_from": "hashed" })
CAP_DB.relations.ensureIndex({ "_to": "hashed" })
EOF
