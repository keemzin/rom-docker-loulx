import zipfile, io, UnityPy, struct

rom_scripts = {}
with zipfile.ZipFile('ROM.apk') as apk:
    z4 = zipfile.ZipFile(io.BytesIO(apk.read('assets/assets4.zip')))
    env = UnityPy.load(io.BytesIO(z4.read('Android/resources/script2/framework.unity3d')))
    for obj in env.objects:
        if obj.type.name == 'TextAsset':
            d = obj.read()
            raw = d.m_Script.encode('utf-8', 'surrogateescape')
            rom_scripts[d.m_Name] = (raw[:8], len(raw))

qj_scripts = {}
with zipfile.ZipFile('client/quick_jump_rom.apk') as apk:
    z32 = zipfile.ZipFile(io.BytesIO(apk.read('assets/assets32.zip')))
    env = UnityPy.load(io.BytesIO(z32.read('Android/resources/script2/framework.unity3d')))
    for obj in env.objects:
        if obj.type.name == 'TextAsset':
            try:
                d = obj.read()
                raw = d.m_Script.encode('utf-8', 'surrogateescape')
                qj_scripts[d.m_Name] = (raw[:8], len(raw))
            except:
                pass

common = set(rom_scripts.keys()) & set(qj_scripts.keys())
print('Common scripts:', len(common))
count = 0
for name in sorted(common):
    qj_first8, qj_len = qj_scripts[name]
    rom_first8, rom_len = rom_scripts[name]
    if qj_first8[:4] == b'czjz' and len(qj_first8) >= 8:
        print(f'{name}: QJ_len={qj_len} ROM_len={rom_len} ROM_start={list(rom_first8[:4])}')
        count += 1
        if count >= 20:
            break
