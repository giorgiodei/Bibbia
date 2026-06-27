#SOMMA INCASSI DEI FILM  CHE I 2 ARTISTI HANNO IN COMUNE
select rm1.name_id as n1, rm2.name_id as n2, SUM( CAST(REPLACE(m.worlwide_gross_income, '$ ', '') AS UNSIGNED) ) AS peso_
from role_mapping rm1 ,role_mapping rm2, ratings r , movie m
where rm1.movie_id = rm2.movie_id
and rm1.name_id < rm2.name_id
and rm1.movie_id = r.movie_id
and rm2.movie_id =r.movie_id
and r.avg_rating BETWEEN "7" and "9"
and r.movie_id = m.id
and m.worlwide_gross_income IS NOT NULL
group BY n1,n2

"""
========================================================================
🎬 BIBBIA SQL: DATABASE IMDB_2 E SIMULAZIONI
Consultorio rapido per PyCharm. Tabelle: actors, roles, movies, names...
========================================================================
"""

# ==============================================================================
# 🎬 IMDB_2 (Base) - Tabelle classiche: actors, roles, movies, movies_directors
# ==============================================================================

# ---> 1. VERTICI: Estrazione Aggregata (Attori con almeno N film)
IMDB_VERTICI_N_FILM = """
SELECT a.id, a.first_name, a.last_name, COUNT(r.movie_id) AS num_film
FROM actors a
JOIN roles r ON a.id = r.actor_id
GROUP BY a.id, a.first_name, a.last_name
HAVING COUNT(r.movie_id) >= %s
"""

# ---> 2. ARCHI: Condivisione Pesata (Attori nello stesso film)
# Trucco: "r1.actor_id < r2.actor_id" evita doppi archi e self-loop
IMDB_ARCHI_STESSO_FILM = """
SELECT r1.actor_id AS a1, r2.actor_id AS a2, COUNT(DISTINCT r1.movie_id) AS peso
FROM roles r1
JOIN roles r2 ON r1.movie_id = r2.movie_id
WHERE r1.actor_id < r2.actor_id
GROUP BY r1.actor_id, r2.actor_id
HAVING peso > 0
"""

# ---> 3. ARCHI: Grafo dei Registi (Catena di join)
# Archi tra registi che hanno diretto lo stesso attore
IMDB_ARCHI_REGISTI_STESSO_ATTORE = """
SELECT md1.director_id AS dir1, md2.director_id AS dir2, COUNT(DISTINCT r1.actor_id) as peso
FROM movies_directors md1
JOIN roles r1 ON md1.movie_id = r1.movie_id
JOIN roles r2 ON r1.actor_id = r2.actor_id -- La cerniera
JOIN movies_directors md2 ON r2.movie_id = md2.movie_id
WHERE md1.director_id < md2.director_id
GROUP BY md1.director_id, md2.director_id
HAVING peso > 0
"""

# ==============================================================================
# 🎥 SIMULAZIONE 2 (Variante IMDB) - Tabelle: names, movie, role_mapping, ratings
# ==============================================================================

# ---> 1. VERTICI CON SUBQUERY: Attori in film con voto > Media Globale
SIM2_VERTICI_MEDIA_GLOBALE = """
SELECT DISTINCT n.id, n.name
FROM names n
JOIN role_mapping rm ON n.id = rm.name_id
JOIN ratings r ON rm.movie_id = r.movie_id
WHERE r.avg_rating > (
    SELECT AVG(avg_rating) FROM ratings
)
"""

# ---> 2. ARCHI TRA FILM: Condivisione Attori e Peso = Somma Voti
SIM2_ARCHI_FILM_STESSI_ATTORI = """
SELECT rm1.movie_id AS m1, rm2.movie_id AS m2, (r1.avg_rating + r2.avg_rating) AS peso
FROM role_mapping rm1
JOIN role_mapping rm2 ON rm1.name_id = rm2.name_id
JOIN ratings r1 ON rm1.movie_id = r1.movie_id
JOIN ratings r2 ON rm2.movie_id = r2.movie_id
WHERE rm1.movie_id < rm2.movie_id
GROUP BY rm1.movie_id, rm2.movie_id
HAVING COUNT(DISTINCT rm1.name_id) >= %s
"""

# ---> 3. ARCHI STRINGHE SPORCHE: Stesso Anno, Peso = Differenza Income
SIM2_ARCHI_STESSO_ANNO_INCOME = """
SELECT rm1.name_id AS n1, rm2.name_id AS n2,
       ABS(CAST(REPLACE(m1.worlwide_gross_income, '$ ', '') AS UNSIGNED) -
           CAST(REPLACE(m2.worlwide_gross_income, '$ ', '') AS UNSIGNED)) AS peso
FROM role_mapping rm1
JOIN movie m1 ON rm1.movie_id = m1.id
JOIN role_mapping rm2 ON m1.year = m2.year
JOIN movie m2 ON rm2.movie_id = m2.id
WHERE rm1.name_id < rm2.name_id
  AND m1.id <> m2.id
  AND m1.worlwide_gross_income IS NOT NULL
  AND m2.worlwide_gross_income IS NOT NULL
GROUP BY rm1.name_id, rm2.name_id
"""

# ==============================================================================
# 🚨 TRUCCO NODI ISOLATI (LEFT JOIN)
# ==============================================================================
# Sposta le restrizioni "WHERE" dentro le "ON" e usa LEFT JOIN.
TRUCCO_NODI_ISOLATI_ZERO = """
SELECT a.id, COUNT(r.movie_id) AS num_horror
FROM actors a
LEFT JOIN roles r ON a.id = r.actor_id
LEFT JOIN movies m ON r.movie_id = m.id AND m.name LIKE '%Horror%'
GROUP BY a.id
"""

# ==============================================================================
# 💡 TEMPLATE DAO ARCHI
# ==============================================================================
def template_get_edges(idMap, param):
    # conn = DBConnect.get_connection()
    # cursor = conn.cursor(dictionary=True)
    # cursor.execute(IMDB_ARCHI_STESSO_FILM, (param,))
    edges = []
    # for row in cursor:
    #     v1 = idMap.get(row["a1"])
    #     v2 = idMap.get(row["a2"])
    #     if v1 is not None and v2 is not None:
    #         edges.append((v1, v2, row["peso"]))
    # cursor.close()
    # conn.close()
    return edges