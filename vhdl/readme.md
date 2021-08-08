
## Formal verification
see: https://www.linkedin.com/pulse/open-source-formal-verification-docker-sverre-hamre/

## Sublime build system
For build use this config, (fix the path to the build.py script)
{
	"cmd": ["python", "(path)\\the-ref\\build.py", "$file", "$file_path", "compile", "$folder"],
	"file_regex": "(\\w*.\\w*):(\\d*):(\\d*):(.*)"
}
For runing the testbencehs use this build config, (fix the path to the build.py script)
{
	"cmd": ["python", "(path)\\the-ref\\build.py", "$file_base_name", "$file_path", "run_tb", "$folder"],
}
