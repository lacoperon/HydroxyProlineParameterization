#!/bin/bash

# This script generates the AMBER parameters for
# trans-3-hydroxyproline, and trans-3-4-dihydroxyproline.
# 2018-06-29 EJW
# Adapted from KMT script for creating staple peptide params

# As seen in the following paper
# https://www.ncbi.nlm.nih.gov/pubmed/24550462

# SET ENVIRONMENT VARIABLES, WORKING DIRECTORY
AMBERHOME=/home/blakhani/amber14
cd data

# STEP 0. Use the two hydroxyproline structures I created,
# and ensure they are placed within the `data` directory

# STEP 1. Rename the 'unknown' residues using sed
# (For dihydroxyproline, PRD, for trans-3-hydroxyproline, PRT)

sed 's/UNK/PRD/g' ejw_dihydroxyproline_draft.pdb > dihydroxypro.pdb
sed 's/UNK/PRT/g' ejw_trans3hydroxyproline_draft.pdb > trans3pro.pdb

# STEP 2. Add hydrogens using 'reduce'

/share/apps/CENTOS6/amber/amber16/bin/reduce -FLIP dihydroxypro.pdb > dihydroxypro_h.pdb
/share/apps/CENTOS6/amber/amber16/bin/reduce -FLIP trans3pro.pdb > trans3pro_h.pdb

# STEP 2. Use `antechamber` to parameterize the AMBER force constants
# and remove all antechamber metafiles. We output the parameters in
# Antechamber (.ac) format, with AMBER atom formatting.
# (As seen in http://ambermd.org/tutorials/basic/tutorial4b/, with modifications)
antechamber -i dihydroxypro_h.pdb -fi pdb -o dihydroxypro.ac -fo ac -c bcc -at amber
antechamber -i trans3pro_h.pdb    -fi pdb -o trans3pro.ac    -fo ac -c bcc -at amber
rm sqm*
rm ANTECHAMBER*
rm ATOMTYPE.INF

# STEP 3. Use `parmchk` to make sure that all parameters are now available
parmchk -i trans3pro.ac    -f ac -o trans3pro.frcmod
parmchk -i dihydroxypro.ac -f ac -o dihydroxypro.frcmod

# STEP 4. MAKE THE MAIN CHAIN FILE (As seen in KMT script)

# HEAD_NAME        -  the N-terminal atom name to connect
# TAIL_NAME        -  C terminal atom name to connect
# MAIN_CHAIN       -  a main chain atom.
# OMIT_NAME        - atoms to delete in the bonded residue
# PRE_HEAD_TYPE    - atom type to which the head atom bonds in previous residue
# POST_TAIL_TYPE   - atop type to which tail atom bonds in next residue
# CHARGE           - charge of the residue

cat <<EOF > trans3pro.mc
HEAD_NAME N
TAIL_NAME C4
MAIN_CHAIN C
OMIT_NAME H8
OMIT_NAME O1
OMIT_NAME H
PRE_HEAD_TYPE C
POST_TAIL_TYPE N
CHARGE 0.0
EOF

cat <<EOF > dihydroxypro.mc
HEAD_NAME N
TAIL_NAME C4
MAIN_CHAIN C
OMIT_NAME H8
OMIT_NAME O1
OMIT_NAME H
PRE_HEAD_TYPE C
POST_TAIL_TYPE N
CHARGE 0.0
EOF

# STEP 5. Run `prepgen` to get prep input files
# (Note that we're also naming our residues here)

prepgen -i trans3pro.ac    -o trans3pro.prepin    -m trans3pro.mc    -rn PRT
prepgen -i dihydroxypro.ac -o dihydroxypro.prepin -m dihydroxypro.mc -rn PRD

# STEP 6. Run `parmchk2` to get the `frcmod` files
# We will use these files to 'plug in' our derived force constants,
# for each of the two modified residues we're adding to our system

parmchk2 -i trans3pro.prepin    -f prepi -o frcmod.pr3 -a Y -p /home/blakhani/amber14/dat/leap/parm/parm10.dat
parmchk2 -i dihydroxypro.prepin -f prepi -o frcmod.prd -a Y -p /home/blakhani/amber14/dat/leap/parm/parm10.dat
