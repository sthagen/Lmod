local version = "1.20"
whatis("Name: Gotoblas")
whatis("Version: " .. version)
whatis("Category: library, mathematics")
whatis("Description: Blas Level 1, 2, 3 routines")
whatis("URL: http://www.tacc.utexas.edu")

local pkgRoot      = "/vol/pkg"
local compiler_dir = firstInPath("LMOD_COMPILER")
local pkgName      = pathJoin("gotoblas",version)
local base         = pathJoin(pkgRoot, compiler_dir, pkgName)
setenv("TACC_GOTOBLAS_DIR",base)
setenv("TACC_GOTOBLAS_LIB",base)

if (os.getenv("LMOD_sys") ~= "Darwin") then
   prepend_path("LD_LIBRARY_PATH",base)
end
