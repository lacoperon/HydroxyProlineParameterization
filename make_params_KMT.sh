#!/bin/bash

# This script generates the parameters for mk8 and 0eh to be used in the Verdine set of stapled alpha helices.
# 2017-09-21 KMT
#
# Note I discovered some problems with this script.  The last update took care of adding the H to backbone N.
# However, I noticed that the staples are not correct; this procedure adds H to the ends of the residues to make
# the CE of mk8 and CAT of 0EH have an octet, but in fact those residues are cross linked, which antechamber does
# not know.  Thus, we introduce stripping out the extra Hs added by antechamber to make the residues ready for cross
# linking in tleap.  The parameters will need to be generated again. Unfortunately the parameters are incorrect
# in the simulations of the peptides so that will need to be redone.  Right now I am rebuilding them to do pulling
# of SAH_8 in water.  I am trying to get the correct starting peptide in a box of water and octanol for pulling
# in /home33/kthayer/PULL/OCTANOL. 2018-01-15 KMT
#
# A note on the unstapled version
# The way the unstapled version of this works is that the staple side chains are as they are here, but another
# 'residue' is added to the chain.  This contains the atoms at the end of the residue prior to their reaction. 
# They are built off a formaldehyde. Then in tleap instead of x-linking the staples to each other, each staple
# gets cross linked to one of these dummy residues to complete the side chains.

# SET ENVIRONMENT VARIABLES
AMBERHOME=/home/blakhani/amber14 
# although I specify the absolute paths here, this is necessary for QM run which spawns jobs
# and requires AMBERHOME to be set in order to use amber14.


# STEP 0.  download 3v3b from the pdb. manually remove chains B and C.
# chain A is the protein MDM2, Chain D is the stapled peptide.
# resulting file is 3v3b_AD.pdb


# STEP 1.  run pdb4amber. Note the one in Bharat's dir points to python that 
# no longer exists.  Use the one in my bin which points to python on cluster.
# /home33/kthayer/

~/bin/pdb4amber -i 3v3b_AD.pdb -o 3v3b_4amber.pdb --dry --reduce


# STEP 2.  DOWNLOAD CIF FILES AND PROCESS NONPRINTING CHARACTERS
# go to the pdb and download the cif files. download them to the working dir.
# cif files: 0eh.cif mk8.cif
# transfer from your desktop to the cluster using winscp.
# process to remove extraneous nonprinting characters

tr -d '\15\32' < 0eh.cif > temp
mv temp 0eh.cif
tr -d '\15\32' < mk8.cif > temp
mv temp mk8.cif


# STEP 3.  USE ANTECHAMBER TO GENERATE THE CHARGES AND ATOM TYPES
/home/blakhani/amber14/bin/antechamber -fi ccif -i mk8.cif -bk MK8 -fo ac -o mk8.ac -c bcc -at amber
# fi - file input format spec
# i - input file name
# bk - residue name found in the input file
# fo - file output format spec
# o - output file name
# c - theory to use to compute the charge
# at - atom types
#
# Note that this procedure will attempt to add any missing H, including the ones at the end of the staples 
# which will need to be removed in STEP 5 below.

/home/blakhani/amber14/bin/antechamber -fi ccif -i 0eh.cif -bk 0EH -fo ac -o 0eh.ac -c bcc -at amber


# STEP 4. UPDATE ATOM TYPES
# Backbone N should be of type N just like all the amino acids, not NT. Fix this.

sed s/" NT"/"  N"/g < 0eh.ac > temp
mv temp 0eh.ac

sed s/" NT"/"  N"/g < mk8.ac > temp
mv temp mk8.ac


# STEP 5. MAKE THE MAIN CHAIN FILE.

# HEAD_NAME        -  the N-terminal atom name to connect
# TAIL_NAME        -  C terminal atom name to connect
# MAIN_CHAIN       -  a main chain atom. 
# OMIT_NAME        - atoms to delete in the bonded residue
# PRE_HEAD_TYPE    - atom type to which the head atom bonds in previous residue
# POST_TAIL_TYPE   - atop type to which tail atom bonds in next residue
# CHARGE           - charge of the residue
#
# Note that I am introducing the omission of HEA and HEB in mk8 and H21 and H22 in oeh 
# which are added during antechamber above. These atoms should be removed in order to make 
# the staple crosslink double bond in later steps with tleap.

# main chain file for mk8:
cat <<EOF > mk8.mc
HEAD_NAME N
TAIL_NAME C
MAIN_CHAIN CA
OMIT_NAME HNA
OMIT_NAME OXT
OMIT_NAME HXT
OMIT_NAME HEA
OMIT_NAME HEB
PRE_HEAD_TYPE C
POST_TAIL_TYPE N
CHARGE 0.0
EOF

# main chain file for 0eh:
cat <<EOF > 0eh.mc
HEAD_NAME NAC
TAIL_NAME CAE
MAIN_CHAIN CAF
OMIT_NAME H8
OMIT_NAME O1
OMIT_NAME H1
OMIT_NAME H21
OMIT_NAME H22
PRE_HEAD_TYPE C
POST_TAIL_TYPE N
CHARGE 0.0
EOF


# STEP 6. RUN PREPGEN TO GET PREP INPUT

/home/blakhani/amber14/bin/prepgen -i 0eh.ac -o 0eh.prepin -m 0eh.mc -rn 0EH
/home/blakhani/amber14/bin/prepgen -i mk8.ac -o mk8.prepin -m mk8.mc -rn MK8

# key outputs:
# mk8.prepin
# 0eh.prepin


# STEP 7. RUN PARMCHK2 TO GET FRCMOD FILE

/home/blakhani/amber14/bin/parmchk2 -i mk8.prepin -f prepi -o frcmod.mk8 -a Y -p /home/blakhani/amber14/dat/leap/parm/parm10.dat 
/home/blakhani/amber14/bin/parmchk2 -i 0eh.prepin -f prepi -o frcmod.0eh -a Y -p /home/blakhani/amber14/dat/leap/parm/parm10.dat

# key outputs:
# frcmod.mk8
# frcmod.0eh

# no missing parameters in either of these files, so a second round of looking for the parameters in gaff is not needed.
# If you did, you'd redo parmchk2 specifying the gaff parameter set of choice on -p.
# and you'd have a second frcmod file. When you get to tleap, you'd read in the gaff frcmod first, and read in the parm10 frcmod
# second to replace most of the atom parameters but leaving the gaff ones for whatever you can't find.



# NEXT STEPS: RUN TLEAP TO GENERATE TOPOLOGY AND COOR FILES FOR SIMULATION IN SYSTEM OF INTEREST

# for your system of interest you can now load up these residues.  Load prepin followed by the parameters in the frcmod.
#
# loadAmberPrep mk8.prepin
# loadAmberparms frcmod.mk8
#
# Do the stapling as before
#


