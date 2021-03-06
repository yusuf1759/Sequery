#! /bin/sh
#
# genpdbselectseq.awk - generate ASCII sequence file for Scripps Sequery program.
#
# Input: name of a PDB file (including path) and a chain ID in this file. 
# Output: to standard output, the file of concatenated pdbseq.asc-format
#  records.
#
# Examples of running this awk script in stand-alone mode (see note below
# about using genpdbselectseq.awk via the genpdbselectseq script):
#
#	genpdbselectseq.awk /psa/pdb/pdb9aat.ent A > pdbselectseq.asc 
#
# Note: Mike Raymer and I made genpdbselectseq.awk, by a small 
# modification of Mike Pique's genpdbseq script, to take two input
# arguments, a PDB code and a chain ID, in order to be able to select specific
# chains to include in the output sequence file.  It is designed to be called by
# genpdbselectseq, which provides it with a list of PDB codes and chains from
# a PDB select file of < 25% identical chains (see documentation at top of
# genpdbselectseq script); this results in a PDB sequence
# file with homologs removed.	The general version of this program, which makes
# a sequence file from all PDB files specified, is the single script genpdbseq 
# written by Mike Pique and updated in 8/96.  genpdbseq accepts wildcards
# as input (e.g., genpdbseq *.pdb > pdb.ascseq) as well as specific filenames.
#
#                               L. Kuhn, MSU 9/3/96 
#						
#
# Note: if you have MANY files (so many you can't expand "*")  do this:
#
#  ls | sort +0.1 | awk '{print "genpdbseq",$1}' | sh > pdbseq.asc
# The sort sorts the name by molecule name rather than version number.
#  -- Mike Pique
#
#
# Technical Notes (MP):
#
#  It is not certain what constitutes a "chain" in PDB but the assumption here
#   is that a chain is a set of CA ATOM records separated by 
#   TER or ENDMDL records
#   or by a change in the chainid (column 22).
#  Duplicate chains are removed.
# 
# Each residue has an integer res_num and a 1-character res_suffix.
# Residue names are either numeric integers or names. A name may appear
# "numeric" if its suffix is a digit, but those are treated as non-numeric.
# It is not clear this is legal PDB but it is fairly common.
# Thus any residue with a non-blank suffix is treated as not numeric.
#
# Any residue name not numeric will be preceded by its name in parentheses,
#  e.g. (100A)V
# Any residue name that is numeric but not one greater than its preceding
# residue, or whose preceding residue was not numeric, will be similarly
# preceded by its name in parentheses.
#
# $Log:	genpdbseq,v $
# Revision 1.3  92/02/17  18:39:07  mp
# (Gary Liao): additions to 3-letter codes, improvements to residue name
# and chain handling.
# 
# Revision 1.2  91/04/26  17:42:13  mp
# Added RCS Log and comments.
# 
#
#
for f in  $1
do
nawk '
BEGIN {id = "'$2'"
	if (id=="_") id = " "}

substr($0,1,3)=="TER" || substr($0,1,6)=="ENDMDL"{
	# new chain
	nchains++;
	}
   substr($0,1,4)=="ATOM" && substr($0,13,4)==" CA " && id==substr($0,22,1){
	if(substr($0,22,1) != chain) {
		# new chain
		nchains++
		chain = substr($0,22,1)
		}
	chainid[nchains] = chain;
# rnum is the residue number
	rnum = 0+substr($0,23,4) 

	# handle rare multiple CA occupancies
	if ((substr($0,17,1)!=" ")&&(res_num[chain,res_index]==rnum)) seq_len[nchains]-=1;

	seq_len[nchains]+=1
	res_index=seq_len[nchains]
	res_type[nchains,res_index] = substr($0,18,3);
	res_num[nchains,res_index] = rnum
	res_suffix[nchains,res_index] = substr($0,27,1)
	chains[chain]=nchains
	}
END{

	# load up the translation table before we start...
	# The upper and lower case forms are common and
	# mixed-case form is as given in Dickerson and Geis. mp
	#
	t["ala"]=t["Ala"]=t["ALA"] = "A"
	t["arg"]=t["Arg"]=t["ARG"] = "R"
	t["asn"]=t["Asn"]=t["ASN"] = "N"
	t["asp"]=t["Asp"]=t["ASP"] = "D"
	t["cys"]=t["Cys"]=t["CYS"] = "C"
	t["gln"]=t["Gln"]=t["GLN"] = "Q"
	t["glu"]=t["Glu"]=t["GLU"] = "E"
	t["gly"]=t["Gly"]=t["GLY"] = "G"
	t["his"]=t["His"]=t["HIS"] = "H"
	t["hip"]=t["Hip"]=t["HIP"] = "H"	# non-standard
	t["hid"]=t["Hid"]=t["HID"] = "H"	# non-standard
	t["hie"]=t["Hie"]=t["HIE"] = "H"	# non-standard
	t["ile"]=t["Ile"]=t["ILE"] = "I"
	t["ilu"]=t["Ilu"]=t["ILU"] = "I"	# old standard
	t["leu"]=t["Leu"]=t["LEU"] = "L"
	t["lys"]=t["Lys"]=t["LYS"] = "K"
	t["met"]=t["Met"]=t["MET"] = "M"
	t["phe"]=t["Phe"]=t["PHE"] = "F"
	t["pro"]=t["Pro"]=t["PRO"] = "P"
	t["ser"]=t["Ser"]=t["SER"] = "S"
	t["thr"]=t["Thr"]=t["THR"] = "T"
	t["trp"]=t["Trp"]=t["TRP"] = "W"
	t["tyr"]=t["Tyr"]=t["TYR"] = "Y"
	t["val"]=t["Val"]=t["VAL"] = "V"

	t["abu"]=t["Abu"]=t["ABU"] = "X"
	t["acd"]=t["Acd"]=t["ACD"] = "U"
	t["alb"]=t["Alb"]=t["ALB"] = "X"
	t["ali"]=t["Ali"]=t["ALI"] = "U"
	t["aro"]=t["Aro"]=t["ARO"] = "U"
	t["asx"]=t["Asx"]=t["ASX"] = "B"
	t["bas"]=t["Bas"]=t["BAS"] = "U"
	t["bet"]=t["Bet"]=t["BET"] = "X"
	t["cyh"]=t["Cyh"]=t["CYH"] = "C"
	t["csh"]=t["Csh"]=t["CSH"] = "C"	
	t["css"]=t["Css"]=t["CSS"] = "C"
	t["cyx"]=t["Cyx"]=t["CYX"] = "C"
	t["glx"]=t["Glx"]=t["GLX"] = "Z"
	t["aib"]=t["Aib"]=t["AIB"] = "X"
	t["unk"]=t["Unk"]=t["UNK"] = "U"
	t["ace"]=t["Ace"]=t["ACE"] = "J"
	t["for"]=t["For"]=t["FOR"] = "J"
	t["hse"]=t["Hse"]=t["HSE"] = "X"
	t["hyl"]=t["Hyl"]=t["HYL"] = "X"
	t["hyp"]=t["Hyp"]=t["HYP"] = "X"
	t["orn"]=t["Orn"]=t["ORN"] = "X"
	t["pca"]=t["Pca"]=t["PCA"] = "X"
	t["pga"]=t["Pga"]=t["PGA"] = "X"
	t["pr0"]=t["Pr0"]=t["PR0"] = "P"
	t["prz"]=t["Prz"]=t["PRZ"] = "P"
	t["sar"]=t["Sar"]=t["SAR"] = "X"
	t["tau"]=t["Tau"]=t["TAU"] = "X"
	t["thy"]=t["Thy"]=t["THY"] = "X"
	t["try"]=t["Try"]=t["TRY"] = "W"

true=1
false=0
for ( c = 1; c<=nchains; c++ ) {
	if(seq_len[c] == 0) continue  # empty
	# remove duplicate chains for this molecule (same length and contents)
	# This is not known to occur in the distributed PDB files
	# but the check is fast 
	#
	# Assume unique, set false if same as any prior "j":
	unique=true
	for(j = 1; j<c; j++) {
		#print "compare",c,"with",j,"lengths=", seq_len[c] ,seq_len[j]
		if(seq_len[c] != seq_len[j]) continue  # cannot be same
		different=false # assume same, set false if any different
		for(i=1;i<=seq_len[c];i++) {
			#print i, res_num[c,i],res_num[j,i], res_suffix[c,i],res_suffix[j,i]
			if(res_num[c,i]!=res_num[j,i] || \
			   res_suffix[c,i] != res_suffix[j,i]) {
				different=true;
				break;
				}
			}
		# get here with different false or true: chain c differs from j
		if(different==false) {
			unique=false;
			break
			}
		} # end loop over j<c
	# get here with unique either false or true
	#if(unique==false) print c,"same as",j
	if(unique==false) continue;
 
			
	id=chainid[c]
	if(id == " ") id = "_"
	printf "%s %1s %4d%1s %5d ", 
	  substr(FILENAME,length(FILENAME)-7,4), id, res_num[c,1], 
	   res_suffix[c,1], seq_len[c]

	next_res_num=res_num[c,1]
	col=19
	for(i=1; i<= seq_len[c]; i++) {
		if((next_res_num!=res_num[c,i])||(res_suffix[c,i]!=" ")) {
			next_res_num=res_num[c,i];
			suffix= res_suffix[c,i];
			if(suffix==" ") suffix=""
			width=2+length(next_res_num)+length(suffix);
			col+=width
			if (col>68) {
			  printf "\n                   " # neatness
			  col=19+width;
			  }
			printf("(%d%s)",next_res_num,suffix);

			# force resync after any suffixed residue
			if(suffix!="")next_res_num = -999;
		}
		res = t[res_type[c,i]]    # look up
		if(res == "") res = "U"  # unknown or missing
		if(col>68) {
			printf "\n                   " # neatness
			col=19;
			}
		printf "%s", res
		col++
		next_res_num++
		}
	printf "\n"
	}
}' $f
done

