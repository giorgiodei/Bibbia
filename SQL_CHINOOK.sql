
========================================================================
🎸 BIBBIA SQL: DATABASE CHINOOK E SIMULAZIONI
Consultorio rapido per PyCharm. Tabelle: Track, Artist, Invoice...
========================================================================

# ==============================================================================
# 🎸 CHINOOK (Base) - Tabelle: Artist, Album, Track, Playlist, Genre
# ==============================================================================

# ---> 1. VERTICI: Filtrati per Genere
CHINOOK_VERTICI_GENERE = """
SELECT t.TrackId, t.Name
FROM Track t
JOIN Genre g ON t.GenreId = g.GenreId
WHERE g.Name = %s


# ---> 2. ARCHI: Differenza (Brani con durata simile)
CHINOOK_ARCHI_DURATA_SIMILE = """
SELECT t1.TrackId AS id1, t2.TrackId AS id2, ABS(t1.Milliseconds - t2.Milliseconds)/1000 AS peso
FROM Track t1, Track t2
WHERE t1.TrackId < t2.TrackId
  AND ABS(t1.Milliseconds - t2.Milliseconds) <= %s


# ---> 3. ARCHI: Artisti nella stessa Playlist
CHINOOK_ARCHI_STESSA_PLAYLIST = """
SELECT al1.ArtistId AS ar1, al2.ArtistId AS ar2, COUNT(DISTINCT pt1.PlaylistId) AS peso
FROM Track t1
JOIN Album al1 ON t1.AlbumId = al1.AlbumId
JOIN PlaylistTrack pt1 ON t1.TrackId = pt1.TrackId
JOIN PlaylistTrack pt2 ON pt1.PlaylistId = pt2.PlaylistId
JOIN Track t2 ON pt2.TrackId = t2.TrackId
JOIN Album al2 ON t2.AlbumId = al2.AlbumId
WHERE al1.ArtistId < al2.ArtistId
GROUP BY al1.ArtistId, al2.ArtistId

# ---> 4. inserire un arco tra due artisti distinti A e B se esiste almeno un cliente che ha acquis-
tato almeno una traccia di entrambi gli artisti, sempre limitatamente al genere e al Paese
selezionati.
Il peso dell’arco è pari al numero di clienti distinti che hanno acquistato tracce di entrambi
gli artisti.

 WITH AcquistiArtisti AS (
            SELECT DISTINCT a.ArtistId, c.CustomerId
            FROM Artist a
            JOIN Album al ON a.ArtistId = al.ArtistId
            JOIN Track t ON al.AlbumId = t.AlbumId
            JOIN Genre g ON t.GenreId = g.GenreId
            JOIN InvoiceLine il ON t.TrackId = il.TrackId
            JOIN Invoice i ON il.InvoiceId = i.InvoiceId
            JOIN Customer c ON i.CustomerId = c.CustomerId
            WHERE g.Name = 'Rock' AND c.Country = 'Brazil'
        )
        SELECT a1.ArtistId AS a1, a2.ArtistId AS a2, COUNT(DISTINCT a1.CustomerId) AS peso
        FROM AcquistiArtisti a1
        JOIN AcquistiArtisti a2 ON a1.CustomerId = a2.CustomerId
        WHERE a1.ArtistId < a2.ArtistId
        GROUP BY a1.ArtistId, a2.ArtistId

# ==============================================================================
# 🛒 SIMULAZIONE 1: CHINOOK VENDITE (Fatturato reale, Invoice, InvoiceLine)
# ==============================================================================

# ---> 1. VERTICI: Artisti per Fatturato Reale (Quantità * Prezzo)
SIM1_VERTICI_FATTURATO_REALE = """
SELECT a.ArtistId, a.Name, SUM(il.UnitPrice * il.Quantity) AS IncassoTotale
FROM Artist a
JOIN Album al ON a.ArtistId = al.ArtistId
JOIN Track t ON al.AlbumId = t.AlbumId
JOIN InvoiceLine il ON t.TrackId = il.TrackId
GROUP BY a.ArtistId, a.Name
HAVING IncassoTotale > %s
"""

# ---> 2. ARCHI: Artisti comprati dallo stesso Cliente (Uso della CTE 'WITH')
# Previene l'esplosione delle Join
SIM1_ARCHI_STESSO_CLIENTE_CTE = """
WITH ArtistCustomers AS (
    SELECT DISTINCT a.ArtistId, i.CustomerId
    FROM Artist a
    JOIN Album al ON a.ArtistId = al.ArtistId
    JOIN Track t ON al.AlbumId = t.AlbumId
    JOIN InvoiceLine il ON t.TrackId = il.TrackId
    JOIN Invoice i ON il.InvoiceId = i.InvoiceId
)
SELECT ac1.ArtistId AS ar1, ac2.ArtistId AS ar2, COUNT(DISTINCT ac1.CustomerId) AS peso
FROM ArtistCustomers ac1
JOIN ArtistCustomers ac2 ON ac1.CustomerId = ac2.CustomerId
WHERE ac1.ArtistId < ac2.ArtistId
GROUP BY ac1.ArtistId, ac2.ArtistId
"""

# ---> 3. ARCHI: Relazione Temporale (Fatture in giorni vicini)
# Su SQLite si usa julianday() per le differenze in giorni
SIM1_ARCHI_FATTURE_VICINE = """
SELECT i1.InvoiceId AS inv1, i2.InvoiceId AS inv2,
       ABS(julianday(i1.InvoiceDate) - julianday(i2.InvoiceDate)) AS diff_giorni
FROM Invoice i1
JOIN Invoice i2 ON i1.CustomerId = i2.CustomerId
WHERE i1.InvoiceId < i2.InvoiceId
  AND ABS(julianday(i1.InvoiceDate) - julianday(i2.InvoiceDate)) <= %s
"""

# ==============================================================================
# 💡 TEMPLATE DAO ARCHI
# ==============================================================================
def template_get_edges(idMap, param):
    # conn = DBConnect.get_connection()
    # cursor = conn.cursor(dictionary=True)
    # cursor.execute(CHINOOK_ARCHI_STESSA_PLAYLIST, (param,))
    edges = []
    # for row in cursor:
    #     v1 = idMap.get(row["ar1"])
    #     v2 = idMap.get(row["ar2"])
    #     if v1 is not None and v2 is not None:
    #         edges.append((v1, v2, row["peso"]))
    # cursor.close()
    # conn.close()
    return edges