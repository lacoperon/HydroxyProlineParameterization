# Hydroxyproline Parameterization for AMBER

This project contains the process of parameterizing up hydroxylated
modifications of Proline as seen in the Pro-64 of the *S. cerevisiae*
ribosomal decoding center, and then adding those modified Prolines to the
PDB structure file, with the aim to set up alternative ribosomal systems that
can then be simulated using Molecular Dynamics using the AMBER suite.

Specifically, it looks at two Proline modifications:
1) *trans*-3-hydroxyproline (seen in higher eukaryotes)
2) dihydroxyproline (seen in lower eukaryotes like budding yeast)

For visual reference of these structures, see Figure 2A of
[Hydroxylation of the eukaryotic ribosomal decoding center affects translational accuracy](http://www.pnas.org/content/111/11/4019).

## Steps of Parameterization
1) Draw up the isolated hydroxyprolyls in Avogadro (ensuring correct stereochemistry)
2) Parameterize that up with antechamber
3) Ensure that molecule can make it through tleap
4) Modify the Ribosomal structure PDB to contain the modified residue, and
ensure this can make it through tleap
5) Enjoy your modified ribosomal structure, ready for MD simulation
