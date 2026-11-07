"""Structural checks runnable without Apple's toolchain; not a Swift build."""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parent
source = (root / 'PixelBloom/Puzzle.swift').read_text()
puzzles = re.findall(r'Puzzle\(id: "([^"]+)".*?rows: \[(.*?)\], palette: \[(.*?)\]\)', source, re.S)
assert len(puzzles) == 21
assert len({p[0] for p in puzzles}) == len(puzzles)
for name, raw_rows, raw_palette in puzzles:
    rows = re.findall(r'"([.0-9A-Z]+)"', raw_rows)
    palette = [int(n) for n in re.findall(r'PaintColor\(id: (\d+)', raw_palette)]
    size = 64 if name.endswith('-64-v1') else 16
    assert len(rows) == size and all(len(row) == size for row in rows), name
    assert len(set(palette)) == len(palette), name
    assert all(c == '.' or int(c, 36) in palette for row in rows for c in row), name
    counts = {n: sum(int(c, 36) == n for row in rows for c in row if c != '.') for n in palette}
    assert all(counts.values()), name
    print(f'{name}: {size}×{size}, {sum(counts.values())} paintable cells, {len(palette)} colors — OK')

pbx = (root / 'PixelBloom.xcodeproj/project.pbxproj').read_text()
ids = re.findall(r'^\s*([A-F0-9]{24})(?: /\*.*?\*/)? = \{', pbx, re.M)
assert len(ids) == len(set(ids)), 'Duplicate project object IDs'
references = set(re.findall(r'\b[A-F0-9]{24}\b', pbx))
assert references == set(ids), 'Dangling project references'
assert 'PBXSourcesBuildPhase' in pbx and 'PBXFrameworksBuildPhase' in pbx
for file in re.findall(r'path = (\w+\.swift);', pbx):
    assert list(root.glob('**/' + file)), file
scheme = ET.parse(root / 'PixelBloom.xcodeproj/xcshareddata/xcschemes/PixelBloom.xcscheme')
for ref in scheme.iter('BuildableReference'):
    assert ref.attrib['BlueprintIdentifier'] in ids
assert scheme.find('.//TestableReference') is not None
print(f'Xcode project: {len(ids)} object references and shared test scheme — OK')
print('Structural checks passed. Swift compilation and XCTest require Xcode on macOS.')
