#!/bin/bash
#===================================================================================
#         FAILAS: kde_l10n.sh
#
#     NAUDOJIMAS: Instrukcijos pateikimos faile SKAITYK.md
#
#      APRAŠYMAS: Scenarijus sukuria pirminę KDE sistemos vertimų failų vietinę 
#                 kopiją, atnaujina failus, išsiunčia pakitimus į KDE repozitoriją
#
# PRIKLAUSOMYBĖS: svn, 
#       AUTORIUS: AKMC komanda (GitHUB prisidėję asmenys)
#      LICENZIJA: GPL v2
#
#        VERSIJA: 0.1
#        IŠLEISTA: 2014-11-10
#===================================================================================

#-----------------------------------------------------------------------------------
# Nustatymai
#-----------------------------------------------------------------------------------

# Verčiama KDE versija
kde_ver='l10n-kf5'

# Verčiama kalba
lang_code='lt'	
lang_name='Lithuanian'	

# Keliai, kur atsiųsti KDE vertimo failus
stable_m='KDE/stable/messages' 			# Stabilios šakos GUI failai
trunk_m='KDE/trunk/messages'			# Trunk GUI failai
trunk_t='KDE/trunk/templates/messages'		# Trunk šablonai

# KDE paskyroje įkelto ssh rakto privati dalis
raktas="${HOME}/.ssh/kde/kde"

# Spalvos
BLUE="\033[7;34m"
BLU="\033[1;34m"
RED="\033[1;31m"
LRED="\033[7;31m"
WHI="\033[1;37m"
NC="\033[0m"
YELLOW="\033[1;33m"
GREL="\033[7;32m"
GRE="\033[1;32m"

#-----------------------------------------------------------------------------------
# Po šitos linijos nerekomenduojama ką nors keisti
#-----------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------
# Funkcijos
#-----------------------------------------------------------------------------------

#--- Funkcija ----------------------------------------------------------------------
#  Pavadinimas: kde_l10n_initiate
#    Aprašymas: KDE vertimo failų pirminis atsisiuntimas
#-----------------------------------------------------------------------------------
kde_l10n_initiate () {
echo "Atsiunčiami KDE sistemos vertimo failai"
# atsiunčiami stabilios šakos vertimo failai (PO)
svn co svn+ssh://svn@svn.kde.org/home/kde/branches/stable/${kde_ver}/${lang_code}/messages $stable_m 
# atsiunčiami trunk vertimo failai (PO)
svn co svn+ssh://svn@svn.kde.org/home/kde/trunk/${kde_ver}/${lang_code}/messages $trunk_m
# atsiunčiami trunk šablonų failai (POT)
svn co svn+ssh://svn@svn.kde.org/home/kde/trunk/${kde_ver}/templates/messages $trunk_t
}

#--- Funkcija ----------------------------------------------------------------------
#  Pavadinimas: kde_l10n_lokalize
#    Aprašymas: KDE vertimo failų pirminis atsisiuntimas
#-----------------------------------------------------------------------------------
kde_l10n_lokalize () {
# Klausimas ar kurti naują Lokalize projektą atsisiustiems vertimo failams
echo -e "Ar sukurti Lokalize projektą? "$BLU"T/N  "$YELLOW"[numatyta NE]$NC"
read PROJ
case "$PROJ" in
t|T)
  echo -e "Kaip pavadinti projektą? "$GRE"(Įveskite pavadinimą ir spauskite Enter)$NC"
  read PROJ_PAV

  LS="lokalize-scripts"				# Taupom kelis simbolius

  # Sukuriamas Lokalize scenarijų aplankas
  if [ ! -d lokalize-scripts ];then		# tikrinamas ar yra jau Lokalize scenarijų aplankas
    mkdir ${LS}
  fi

  # Gaminamas msgfmt.py failas
  echo -e "# -*- coding: utf-8 -*-
  import os,sys
  import Editor
  import Project\n
  def doCompile():
  \tif not Editor.isValid() or Editor.currentFile=='': return
  \tlang=Project.targetLangCode()\n
  \t(path, pofilename)=os.path.split(Editor.currentFile())
  \t(package, ext)=os.path.splitext(pofilename)
  \tif os.system('touch \`kde4-config --localprefix\`/share/locale/%s/LC_MESSAGES' % lang)!=0:
  \t\tos.system('mkdir \`kde4-config --localprefix\`/share')
  \t\tos.system('mkdir \`kde4-config --localprefix\`/share/locale')
  \t\tos.system('mkdir \`kde4-config --localprefix\`/share/locale/%s'  % lang)
  \t\tos.system('mkdir \`kde4-config --localprefix\`/share/locale/%s/LC_MESSAGES'  % lang)\n
  \tos.system('msgfmt -o \`kde4-config --localprefix\`/share/locale/%s/LC_MESSAGES/%s.mo %s' % (lang, package, Editor.currentFile()))\n
  doCompile()" > ${LS}/msgfmt.py

  # Gaminamas msgfmt.rc failas
  echo -e "<KrossScripting>
  \t<collection comment=\"Tools\" name=\"tools\" text=\"Tools\" >
  \t\t<script icon=\"text-x-python\" comment=\"Kompiliuoja po ir padeda jį į ~/.kde\" name=\"msgfmt\" file=\"msgfmt.py\" interpreter=\"python\" text=\"Kompiliuoti PO\" />
  \t</collection>
  </KrossScripting>>" > ${LS}/msgfmt.rc

  # Gaminamas scripts.rc failas
  echo -e "<KrossScripting>
  \t<collection comment=\"Įrankiai\" name=\"tools\" text=\"Įrankiai\">
  \t\t<script icon=\"text-x-python\" comment=\"Compiles po and places it under ~/.kde\" name=\"msgfmt\" file=\"msgfmt.py\" interpreter=\"python\" text=\"Kompiliuoti PO\"/>
  \t</collection>
  </KrossScripting>" > ${LS}/scripts.rc

  # Gaminamas lokalize projekto failas | reikia aiškinamojo žodyno kelią sutvarkyti
  echo -e "[General]
  BranchDir=./KDE/stable/messages
  LangCode=${lang}
  PoBaseDir=./KDE/trunk/messages
  PotBaseDir=./KDE/trunk/templates/messages
  ProjectID=$PROJ_PAV
  TargetLangCode=${lang}" > $PROJ_PAV.lokalize
;;

*)
  echo -e ""
  echo -e ""$YELLOW"Nutraukta\n$NC"
esac
}

#--- Funkcija ----------------------------------------------------------------------
#  Pavadinimas: kde_l10n_update
#    Aprašymas: KDE vertimo failų atnaujinimas
#-----------------------------------------------------------------------------------
kde_l10n_update () {
eval `ssh-agent -s`
ssh-add ${raktas}

svn update ${stable_m}
svn update ${trunk_m}
svn update ${trunk_t}

echo ""
echo "Baigta! Gero vertimo!"
}

#--- Funkcija ----------------------------------------------------------------------
#  Pavadinimas: kde_l10n_commit
#    Aprašymas: KDE vertimo failų nusiuntimas į repozitoriją
#-----------------------------------------------------------------------------------
kde_l10n_commit () {
eval `ssh-agent -s`
ssh-add ${raktas}

svn commit --message 'Updated ${lang_name} translation' ${stable_m}
svn commit --message 'Updated ${lang_name} translation' ${trunk_m}

echo ""
echo "Baigta! Bendruomenė tavęs nepamirš!"
}

#--- Funkcija ----------------------------------------------------------------------
#  Pavadinimas: pause
#    Aprašymas: Stabdomas scenarijus ir nukreipiama atgal į meniu
#-----------------------------------------------------------------------------------
pause() {
read -p "$*"
}

#--- Funkcija ----------------------------------------------------------------------
#  Pavadinimas: kde_l10n_menu
#    Aprašymas: Rodomas pagalbininko meniu
#-----------------------------------------------------------------------------------
kde_l10n_menu () {
  clear
  echo -e "**********************************************************************"
  echo -e "                  KDE sistemos vertimo pagalbininkas                  "
  echo -e "**********************************************************************$NC"
  echo -e ""
  echo -e "[1] Inicijuoti pirmą atsiuntimą         [P] Pagalba"
  echo -e "[2] Atnaujinti vertimo failus           [Q] Išeiti"
  echo -e "[3] Išsiųsti išverstus failus"
  echo -e "[4] Sukurti Lokalize programos projektą"
  echo -e ""
  echo -e "**********************************************************************$NC"
  echo -e ""$YELLOW"Vykdyti komandą pagal jos numerį arba raidę:$NC"
  echo -e ""
  read opt
  case $opt in

P|p)
  less -c SKAITYK.md
  kde_l10n_menu
;;

1|init)
#   echo -e "Pirma komanda"
  kde_l10n_initiate
  echo -e ""
  echo -e ""$GRE"Spauskite ENTER, kad rodyti Meniu$NC"
  pause
  kde_l10n_menu
;;

2|update|up)
#   echo -e "Antra komanda"
  kde_l10n_update
  echo -e ""
  echo -e ""$GRE"Spauskite ENTER, kad rodyti Meniu$NC"
  pause
  kde_l10n_menu
;;

3|upload|commit)
#   echo -e "Trečia komanda"
  kde_l10n_commit
  echo -e ""
  echo -e ""$GRE"Spauskite ENTER, kad rodyti Meniu$NC"
  pause
  kde_l10n_menu
;;

4|lokalize)
#   echo -e "Trečia komanda"
  kde_l10n_lokalize
  echo -e ""
  echo -e ""$GRE"Spauskite ENTER, kad rodyti Meniu$NC"
  pause
  kde_l10n_menu
;;

Q|q|quit|exit)
  echo -e ""$GRE"Ar tikrai norite išeiti? t/n [numatyta taip]$NC"
  read SNE
  case $SNE in
  t|"")
    clear
    echo -e "$GREL                  Dėkui, kad verčiate KDE sistemą                 $NC"
    echo -e ""
    exit
  ;;
  n|N)
    kde_l10n_menu
  ;;
  *)
    echo -e ""
    echo -e ""$RED"!!!DĖMESIO!!! Nežinoma komanda!! $NC"
    sleep 2
    kde_l10n_menu
  ;;
  esac
;;

*)
  echo -e ""
  echo -e ""$RED"!!!Dėmesio!!! Nežinoma komanda!! $NC"
  sleep 1
  kde_l10n_menu
;;
esac
}
# Rodome meniu
kde_l10n_menu