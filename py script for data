import vertica_python as vp
from verticapy import *
import pandas as pd
from os import listdir
from os.path import isfile, join

conn = {
    'host': 'localhost',
    'port': 5433,
    'user': 'dbadmin',
    'password': '',
    'database': 'VMart'
}

with vp.connect(**conn) as connection:
    cur = connection.cursor()
    path = "C:\\Users\\User\\Desktop\\sandbox.KNU"
    # усі папки головної це схеми файли в них тейбли
    schemas = [f for f in listdir(path) if not isfile(join(path, f))]
    for sch in schemas:
        tables = [f for f in listdir(path + "\\" + sch) if isfile(join(path + "\\" + sch, f))]
        for t in tables:
            tpath = path + "\\" + sch + "\\" + t
            print(tpath)
            df_init = pd.read_csv(tpath, delimiter='\t')#в датафрейм пандасу файл
            df = pandas_to_vertica(df=df_init, name=t[:-4:], cursor=cur, schema=sch)#в датафрейм вертіки з дф пандасу
            try: #записуемо датафрейм вертіки в бд
                df.to_db(name=sch+"."+t[:-4:], relation_type='table')
            except vp.errors.DuplicateObject: #якщо вже тейбл існуе то ми зловимо виключення і перезапищемо
                df.to_db(name=sch + "." + t[:-4:], relation_type='insert')
            connection.commit() #комітимо зміну
    cur.closed()
