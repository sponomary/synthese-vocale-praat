clearinfo

#################################################
#           PREPARATION DU PROGRAMME            #
#################################################

# ----------------------------------------------#
# Déclaration des variables d'accès aux fichiers
# ----------------------------------------------#
# Chemin relatif
chemin_son$ = "ponomareva.wav"
chemin_segmentation$ = "ponomareva.Textgrid"
chemin_dico$ = "dico.txt"
chemin_fichier_final$ = "resultat.wav"

# ----------------------------------------------#
# Ouverture du fichier son
# ----------------------------------------------#
son = Read from file: chemin_son$
# Fréquence d'échantillonnage : nombre d'échantillons par seconde. 
# Doit être mis après l'ouverture du fichier son ou ailleurs avec select 'son'
# Sound -> Query -> Query time sampling -> Get sampling frequency 
freq_echant = Get sampling frequency
# Récupération de toutes les intersections avec 0
select 'son'
intersection = To PointProcess (zeroes): 1, "no", "yes"

# ----------------------------------------------#
# Ouverture du fichier avec la Textgrid
# ----------------------------------------------#
segmentation = Read from file: chemin_segmentation$
# Il doit être mis après l'ouverture du fichier segmentation
nb_cases = Get number of intervals: 1

# ----------------------------------------------#
# Ouverture du dictionnaire
# ----------------------------------------------#
dico = Read Table from tab-separated file: chemin_dico$

# ----------------------------------------------#
# On crée un fichier dans  lequel on va concaténer les diphones 
# ----------------------------------------------#
# On corrige le nom  du son et la durée de silence (0,1 ou même 0,05s)
# New -> Sound -> Create sound from formula -> Get number of intervals -> Formula : 0
# ATTENTION A LA FREQUENCE D'ECHANTILLONNAGE
fichier_phrase = Create Sound from formula: "fichiersynthetise", 1, 0, 0.05, 44100, "0"





#################################################
#             DÉBUT DU PROGRAMME                #
#################################################

# ----------------------------------------------#
# Constitution du formulaire
# ----------------------------------------------#
# On crée une boite de dialogue pour saisir la phrasese à synthétiser
form Synthetiseur vocale (TAL M1)
 	comment Quelle phrase voulez-vous synthétiser ?

	optionmenu Choisir_la_phrase: 1
		
		option 1. il pleut fort		
		option 2. il pleut il mouille		
		option 3. j'aime mes jouets	
		option 4. notre village est joli		
		option 5. les papillons volent au-dessus de la ville
		option 6. petit escargot porte sur son dos sa maisonnette
		option 7. aussitôt qu'il pleut il est tout heureux
		option 8. il sort sa tête
		option 9. sa tête est jolie


	comment Ou saisir un mot / une phrase dans le champs texte ci-dessous :
	text mot_ortho

	comment _________________________________________________________________________________
	comment Voulez-vous une modification prosodique ?
		boolean F0
    		boolean Duree

	comment F0 options:
		integer F0_debut_(Hz) 250
		integer F0_variation_entre_mot(Hz) 20
		integer F0_variation_mot(Hz) 15

	comment Duree options:
		real Duree_debut 0.7
		real Duree_milieu 0.8
		real Duree_fin 0.7
		
	comment _________________________________________________________________________________
	comment Voulez-vous enregistrer le fichier .wav à la fin ?
		boolean Enregistrement 1
	comment Voulez-vous supprimer les objets PRAAT à la fin du traitement  ?
		boolean Supprimer 1
endform

# ----------------------------------------------#
# Liste de phrases et de mots pour la F0
# ----------------------------------------------#
f0_mot_en_cours = f0_debut
f0_pas = f0_variation_entre_mot
f0_mot = f0_variation_mot
sommet = 0

# Liste de phrases
list_phrase$ [1] = "il pleut fort"
list_phrase$ [2] = "il pleut il mouille"
list_phrase$ [3] = "j'aime mes jouets"
list_phrase$ [4] = "notre village est joli"
list_phrase$ [5] = "les papillons volent au-dessus de la ville"
list_phrase$ [6] = "petit escargot porte sur son dos sa maisonnette"
list_phrase$ [7] = "aussitôt qu'il pleut il est tout heureux"
list_phrase$ [8] = "il sort sa tête"
list_phrase$ [9] = "sa tête est jolie"

# Liste de mot pour la F0
list_sommet_f0$ [1] = "pleut"
list_sommet_f0$ [2] = "pleut"
list_sommet_f0$ [3] = "j'aime"
list_sommet_f0$ [4] = "est"
list_sommet_f0$ [5] = "volent"
list_sommet_f0$ [6] = "porte"
list_sommet_f0$ [7] = "pleut"
list_sommet_f0$ [8] = "sort"
list_sommet_f0$ [9] = "est"

# On a choisit une phrase dans la liste déroulante
if ( mot_ortho$ = "" )
	mot_ortho$ = list_phrase$[choisir_la_phrase]
	phrase_saisie = 0
else
	phrase_saisie = 1
endif

# ----------------------------------------------#
# Parcourir l'ensemble des mots de la phrase
# ----------------------------------------------#
repeat
	espace = index(mot_ortho$, " ")
	premier_mot$ = mid$(mot_ortho$,1,espace-1)

	# Le reste de la phrase
	mot_ortho$ = mid$(mot_ortho$,espace+1,length(mot_ortho$))
	
	# Traitement du dernier mot de la phrase (car pas d'espace après le dernier mot)
	if espace = 0
		premier_mot$ = mot_ortho$
	endif

	# --------------------------------------------------------------------------------------------#
	# Appeler la fonction/procédure avec la variable premier_mot$ (a chaque boucle) pour synthétiser mot par mot
	# --------------------------------------------------------------------------------------------#
	@getSyntheseMot: premier_mot$
	
until espace = 0


# ----------------------------------------------#
# Modification prosodique de la durée (pour la phrase)
# ----------------------------------------------#
if ( duree )
	@modificationDuree
endif

# ----------------------------------------------#
# Lecture du fichier son obtenu
# ----------------------------------------------#
select 'fichier_phrase'
Play

# ----------------------------------------------#
# Enregistrement du fichier son obtenu
# ----------------------------------------------#
if ( enregistrement )
	Save as WAV file: chemin_fichier_final$
endif

# Fin du programme et nettoyage
if ( supprimer )
	select all
	Remove
endif

#################################################
#             FIN DU PROGRAMME                  #
#################################################






#################################################
#             PROCÉDURES DU PROGRAMME           #
#################################################

# ---------------------------------------#
# 01 Procédure de synthèse d'un mot      #
# ---------------------------------------#
procedure getSyntheseMot: mot_synthetise$

	fichier_mot = Create Sound from formula: "fichiersynthetise", 1, 0, 0.05, 44100, "0"

	if ( phrase_saisie = 0 )
		# Si le mot est égal au mot du sommet de la F0
		if (mot_synthetise$ = list_sommet_f0$[choisir_la_phrase])
			sommet = 1
		endif
	endif
	
	selectObject: 'dico'
	# On récupère l'équivalent phonétique de mot_ortho$ daans le dictionnaire
	extract_dico = Extract rows where column (text): "orthographe", "is equal to", mot_synthetise$
	
	mot_phonetique$ = Get value: 1, "phonetique"
	mot_phonetique$ = "_" + mot_phonetique$ + "_"

	# Nettoyage des objets dico
	removeObject: extract_dico ;

	appendInfoLine: "Traitement du mot: ", mot_synthetise$, " --> En phonétique: ", mot_phonetique$

	# On récupère le nombre de caractères du mot phonétique (avec les _ avant et après)
	nb_caracteres = length(mot_phonetique$)


	for y from 1 to nb_caracteres-1
		diphone$ = mid$(mot_phonetique$,y,2)
		phoneme1$ = mid$(diphone$,1,1)
		phoneme2$ = mid$(diphone$,2,1)
		
		diphoneTrouve = 0
		for x from 2 to nb_cases
			select 'segmentation'
			label_intervalle$ = Get label of interval: 1, x
			label_intervalle_pr$ = Get label of interval: 1, x-1

			if (label_intervalle_pr$ = phoneme1$ and label_intervalle$ = phoneme2$)
				diphoneTrouve = diphoneTrouve + 1

				# Récupération des temps de début et de fin des phonèmes
				temps_debut_pr = Get start time of interval: 1, x-1
				temps_debut = Get start time of interval: 1, x   
				temps_fin = Get end time of interval: 1, x
				
				# Calcul du temps du milieu des phonèmes
				milieu_pr = temps_debut_pr + ((temps_debut - temps_debut_pr) / 2)
				milieu = temps_debut + ((temps_fin - temps_debut) / 2)

				# Recherche du temps correspondand à l'intersection avec 0 la plus proche
				# pour une meilleure concaténation
				select 'intersection'
				indice_proche = Get nearest index: milieu_pr
				intersection_zero_pr = Get time from index: indice_proche

				indice_proche = Get nearest index: milieu
				intersection_zero = Get time from index: indice_proche

				# Extraction du son du diphone
				select 'son'
				extrait_son = Extract part: intersection_zero_pr, intersection_zero, "rectangular", 1, "no"

				# Concaténation du diphone
				select 'fichier_mot'
				plus 'extrait_son'
				fichier_mot = Concatenate

				# Nettoyage des objets extrait son 
				removeObject: extrait_son ;
			endif
		endfor
		
		# Gestion des erreurs de diphone
		if diphoneTrouve = 0
			appendInfoLine: "Diphone non trouvé dans le fichier de segmentation : ", diphone$
		endif

	endfor

	# ----------------------------------------------#
	# Modification prosodique de la F0 par mot
	# ----------------------------------------------#
	if ( f0 && phrase_saisie = 0 )
		@modificationF0
	endif


	# Concaténation du mot à la phrase
	select 'fichier_phrase'
	plus 'fichier_mot'
	fichier_phrase = Concatenate
	
endproc


# --------------------------------------------------#
# 02 Procédure de modification prosodique de f0     #
# --------------------------------------------------#

procedure modificationF0

	selectObject: 'fichier_mot'
	endTime=Get end time
	manipulationProso = To Manipulation: 0.01, 75, 600
	extractPitch = Extract pitch tier
	Remove points between: 0, endTime

	Add point: 0.01, f0_mot_en_cours
	Add point: endTime/2, f0_mot_en_cours + f0_mot
	Add point: endTime, f0_mot_en_cours

	
	select 'manipulationProso' 
	plus 'extractPitch' 
	Replace pitch tier

	select 'manipulationProso' 
	fichier_mot = Get resynthesis (overlap-add)

	
	if ( sommet )
		# Permet à la f0 de redescendre après le sommet (souvent le verbe)
		f0_mot_en_cours = f0_mot_en_cours - f0_pas
	else
		# Permet à la f0 de monter jusqu'au mot du sommet (souvent le verbe)
		f0_mot_en_cours = f0_mot_en_cours + f0_pas
	endif

endproc


# ---------------------------------------#
# 03 Procédure de modification de durée  #
# ---------------------------------------#

procedure modificationDuree

	selectObject: 'fichier_phrase'
	endTime=Get end time
	manipulationProso = To Manipulation: 0.01, 75, 600
	modificationDuree = Extract duration tier
	Remove points between: 0, endTime

	Add point: 0.01, duree_debut
	Add point: endTime*0.5, duree_milieu
	Add point: endTime, duree_fin


	select 'manipulationProso' 
	plus 'modificationDuree' 
	Replace duration tier

	select 'manipulationProso' 
	fichier_phrase = Get resynthesis (overlap-add)

endproc