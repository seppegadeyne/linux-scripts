#!/usr/bin/env python3
import sys
from itertools import chain
from fontTools.ttLib import TTFont
from fontTools.subset import Subsetter
from fontTools.ttLib.woff2 import compress

def print_help():
    print("Usage: extract_latin <path/to/your/input_font.ttf>")
    print("\nThis script subsets the specified font file, keeping only the specified Unicode ranges and characters.")
    print("\nDependencies:")
    print("  - Python 3")
    print("  - FontTools: Install using 'pip install fonttools'\n")

if len(sys.argv) != 2 or sys.argv[1] in ('-h', '--help'):
    print_help()
    sys.exit(1)

input_font_path = sys.argv[1]
output_font_path = input_font_path[:-4] + "_subset.woff2"

font = TTFont(input_font_path)

unicode_ranges = [
    range(0x0000, 0x0100),
    [0x0131],
    range(0x0152, 0x0154),
    range(0x02BB, 0x02BD),
    [0x02C6, 0x02DA, 0x02DC],
    range(0x2000, 0x2070),
    [0x2074, 0x20AC, 0x2122, 0x2191, 0x2193, 0x2212, 0x2215, 0xFEFF, 0xFFFD],
]

subsetter = Subsetter()
subsetter.populate(unicodes=list(chain.from_iterable(unicode_ranges)))

subsetter.subset(font)

with open(output_font_path, 'wb') as woff2_file:
    woff2_data = compress(font)
    woff2_file.write(woff2_data)

print(f"Subsetted WOFF2 font saved to: {output_font_path}")
