"""Apply the exact packaged PHP 7.3.4 source replacements after checking inputs.
Only writes the supplied separate source directory; never installs a runtime.
"""
from pathlib import Path
import argparse
import hashlib
import json
ROOT=Path(__file__).resolve().parent
def sha(data):return hashlib.sha256(data).hexdigest()

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source',required=True,type=Path)
    source=parser.parse_args().source.resolve(strict=True)
    rows=json.loads((ROOT/'source-changes.json').read_text())['changed_files']
    pending=[]
    for row in rows:
        destination=(source/row['file']).resolve();destination.relative_to(source)
        before=destination.read_bytes() if destination.exists() else None
        if (sha(before) if before is not None else None)!=row['before']:
            raise SystemExit('Source is not pristine PHP 7.3.4: '+row['file'])
        data=(ROOT/'patched-source'/row['file']).read_bytes()
        if sha(data)!=row['after']:raise SystemExit('Replacement SHA-256 mismatch: '+row['file'])
        pending.append((destination,data))
    for destination,data in pending:
        destination.parent.mkdir(parents=True,exist_ok=True);destination.write_bytes(data)
    print('Applied '+str(len(pending))+' hash-checked source replacements; unofficial PHP source port.')

if __name__=='__main__':main()
