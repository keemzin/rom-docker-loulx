import os

versions = [
    'update_20160817_1', 'update_20160908_1', 'update_20160928_1', 'update_20160928_2',
    'update_20160930_1', 'update_20161008_1', 'update_20161009_1', 'update_20161012_1',
    'update_20161012_2', 'update_20161013_1', 'update_20161014_1', 'update_20161014_2',
    'update_20161015_1', 'update_20161017_1', 'update_20161018_1', 'update_20161018_2',
    'update_20161019_1', 'update_20161020_1', 'update_20161022_1', 'update_20161022_2',
    'update_20161025_1', 'update_20161026_3', 'update_20161102_1', 'update_20161104_1',
    'update_20161108_1', 'update_20161109_1', 'update_20161111_1', 'update_20161115_1',
    'update_20161118_1', 'update_20161121_1', 'update_20161124_1', 'update_20161124_2',
    'update_20161201_1', 'update_20161203_1', 'update_20161206_1', 'update_20161208_1',
    'update_20161209_1', 'update_20161215_1', 'update_20161217_1', 'update_20161221_1',
    'update_20161222_1', 'update_20161223_1', 'update_20161226_1', 'update_20161226_2',
    'update_20161228_1', 'update_20170105_1', 'update_20170106_1', 'update_20170117_1',
    'update_20170120_1', 'update_20170122_1', 'update_20170207_1', 'update_20170210_1',
    'update_20170210_2', 'update_20170217_2', 'update_20170218_1', 'update_20170220_1',
    'update_20170220_2', 'update_20170223_1', 'update_20170223_2', 'update_20170224_2',
    'update_20170224_3', 'update_20170314_1', 'update_20170401_1', 'update_20170410_1',
    'update_20170414_1', 'update_20170502_1', 'update_20170506_1', 'update_20170506_2',
    'update_20170510_1', 'update_20170518_1', 'update_20170619_1', 'update_20170622_1',
    'update_20170714_1', 'update_20170804_1', 'update_20170809_1', 'update_20170811_1',
    'update_20170821_1', 'update_20170905_1', 'update_20170911_1', 'update_20170920_1',
    'update_20170927_1', 'update_20171009_1', 'update_20171011_1', 'update_20171026_1',
    'update_20171031_1', 'update_20171102_1', 'update_20171120_1', 'update_20171122_1',
    'update_20171123_1', 'update_20171130_1', 'update_20171207_1', 'update_20171208_1',
    'update_20171211_1', 'update_20171219_1', 'update_20171220_1', 'update_20171225_1',
    'update_20171226_1', 'update_20171228_1', 'update_20171229_1', 'update_20180104_1',
    'update_20180111_1', 'update_20180115_1', 'update_20180122_1', 'update_20180129_1',
    'update_20180131_1', 'update_20180208_1', 'update_20180228_1', 'update_20180306_1',
    'update_20180312_1', 'update_20180404_1', 'update_20180413_1', 'update_20180416_1',
    'update_20180419_1', 'update_20180505_1', 'update_20180505_2', 'update_20180511_1',
    'update_20180512_1', 'update_20180517_1', 'update_20180601_1', 'update_20180615_1',
    'update_20180619_1', 'update_20180704_1', 'update_20180711_1', 'update_20180727_1',
    'update_20180730_1', 'update_20180731_1', 'update_20180802_1', 'update_20180803_1',
    'update_20180813_1', 'update_20180819_1', 'update_20180906_1', 'update_20180913_1',
    'update_20180921_1'
]

vals = ", ".join(f"('{v}')" for v in versions)
insert_stmt = f"INSERT INTO `updatesql` VALUES {vals};\n"

for fpath in ['db/init/02_ro_xd_r2.sql', 'BACKUP/loulx-migration/db/loulx_ro_xd_r2.sql']:
    if not os.path.exists(fpath):
        print(f"File not found: {fpath}")
        continue
    with open(fpath, 'rb') as f:
        content = f.read()
    
    target_lf = b"LOCK TABLES `updatesql` WRITE;\n/*!40000 ALTER TABLE `updatesql` DISABLE KEYS */;\n"
    target_crlf = b"LOCK TABLES `updatesql` WRITE;\r\n/*!40000 ALTER TABLE `updatesql` DISABLE KEYS */;\r\n"
    
    if b"update_20160817_1" in content:
        print(f"Already patched: {fpath}")
        continue
        
    if target_lf in content:
        rep = target_lf + insert_stmt.encode('utf-8')
        content = content.replace(target_lf, rep, 1)
        with open(fpath, 'wb') as f:
            f.write(content)
        print(f"Successfully patched (LF): {fpath}")
    elif target_crlf in content:
        rep = target_crlf + insert_stmt.replace('\n', '\r\n').encode('utf-8')
        content = content.replace(target_crlf, rep, 1)
        with open(fpath, 'wb') as f:
            f.write(content)
        print(f"Successfully patched (CRLF): {fpath}")
    else:
        print(f"Target pattern not found in {fpath}")
