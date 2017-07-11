# -*- lua -*-
propT = {
   lmod = {
      validT = { sticky = 1 },
      displayT = {
         sticky = { short = "(S)",  long = "(S)",   color = "red", doc = "Module is Sticky, requires --force to unload or purge",  },
      },
   },
   type_ = {
      validT = { tools = 1, mpi = 2, script = 3, math = 4, chem = 5, bio = 6, vis = 7, phys = 8, geo = 9, io = 10, ai = 11 },
      displayT = {
         ["tools"]     = { short = "(t)",  long = "(tool)",   color = "blue", doc = "Tools for development / Outils de développement", },
         ["mpi"]     = { short = "(m)",  long = "(mpi)",   color = "red", doc = "MPI implementations / Implémentations MPI", },
         ["script"]     = { short = "(s)",  long = "(script)",   color = "yellow", doc = "Scripting language / Langages de script", },
         ["math"]     = { short = "(math)",  long = "(math)",   color = "green", doc = "Mathematical libraries / Bibliothèques mathématiques", },
         ["chem"]     = { short = "(chem)",  long = "(chem)",   color = "magenta", doc = "Chemistry libraries/apps / Logiciels de chimie", },
         ["phys"]     = { short = "(phys)",  long = "(phys)",   color = "cyan", doc = "Physics libraries/apps / Logiciels de physique", },
         ["geo"]     = { short = "(geo)",  long = "(geo)",   color = "cyan", doc = "Geography libraries/apps / Logiciels de géographie", },
         ["bio"]     = { short = "(bio)",  long = "(bio)",   color = "red", doc = "Bioinformatic libraries/apps / Logiciels de bioinformatique", },
         ["vis"]     = { short = "(vis)",  long = "(vis)",   color = "blue", doc = "Visualisation software / Logiciels de visualisation", },
         ["io"]     = { short = "(io)",  long = "(io)",   color = "yellow", doc = "Input/output software / Logiciel d'écriture/lecture", },
         ["ai"]     = { short = "(ai)",  long = "(ai)",   color = "yellow", doc = "Artificial intelligence", }, 
      },
   },
}

