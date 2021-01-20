Minimal implementation of some of Azimuth's functionality.

To run, after [installing cairo](https://www.cairo-lang.org/docs/quickstart.html):

    cairo-compile ./az.cairo --output compiled.json
    python3 az.py 155 > deed.json
    cairo-run --program=compiled.json --print_output --print_info --relocate_prints --layout=small --program_input=deed.json --debug_error
