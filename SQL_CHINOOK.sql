
========================================================================
🎸 BIBBIA SQL: DATABASE CHINOOK E SIMULAZIONI
Consultorio rapido per PyCharm. Tabelle: Track, Artist, Invoice...
========================================================================

# ==============================================================================
# 🎸 CHINOOK (Base) - SELECT & Filtri
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

# ---> 3.Track più lunghe di 5 minuti
Milliseconds > 300000 (5 min = 300s = 300000ms). Mostra nome e durata in secondi.
SELECT Name,
       ROUND(Milliseconds / 1000.0, 1) AS DurataSecondi
FROM Track
WHERE Milliseconds > 300000
ORDER BY Milliseconds DESC;


# ---> 4. Fatture in un intervallo di date
Filtraggio temporale con BETWEEN o confronto diretto su date.
SELECT InvoiceId, InvoiceDate, Total
FROM Invoice
WHERE InvoiceDate BETWEEN '2009-01-01' AND '2009-12-31'
ORDER BY InvoiceDate;


# ---> 5. INNER JOIN: restituisce solo artisti che hanno almeno un album.
SELECT ar.Name AS Artista, al.Title AS Album
FROM Artist ar
JOIN Album al ON ar.ArtistId = al.ArtistId
ORDER BY ar.Name, al.Title;
⚠ Trappola: con LEFT JOIN si vedono anche gli artisti senza album (NULL in Title).

# ---> 6. Self-JOIN: gerarchia Employee (manager)
Employee ha un FK su se stessa: ReportsTo → EmployeeId. Classica domanda sull'auto-join.
SELECT e.FirstName, e.LastName,
       m.FirstName AS ManagerFirstName,
       m.LastName  AS ManagerLastName
FROM Employee e
LEFT JOIN Employee m ON e.ReportsTo = m.EmployeeId
ORDER BY m.LastName, e.LastName;
💡 Nota: LEFT JOIN perché il CEO non ha manager (ReportsTo = NULL).

# ---> 7. Customer → Employee (supporto) → Invoice. Mostra nome cliente, dipendente di supporto, totale speso.

SELECT c.FirstName, c.LastName,
       e.FirstName AS SupportRep,
       SUM(i.Total) AS TotaleSpeso
FROM Customer c
JOIN Employee e ON c.SupportRepId = e.EmployeeId
JOIN Invoice  i ON c.CustomerId  = i.CustomerId
GROUP BY c.CustomerId, e.EmployeeId
ORDER BY TotaleSpeso DESC;

# --> 8. Numero di album per artista
Aggregazione base: COUNT + GROUP BY.

SELECT ar.Name, COUNT(al.AlbumId) AS NumAlbum
FROM Artist ar
LEFT JOIN Album al ON ar.ArtistId = al.ArtistId
GROUP BY ar.ArtistId, ar.Name
ORDER BY NumAlbum DESC;

# --> 9.Totale vendite per paese
SUM del totale fatture raggruppate per BillingCountry.
SELECT BillingCountry,
       COUNT(InvoiceId)            AS NumFatture,
       ROUND(SUM(Total), 2)       AS TotaleVendite
FROM Invoice
GROUP BY BillingCountry
ORDER BY TotaleVendite DESC;

# --> 10. Durata media track per genere
AVG + JOIN Genre.
SELECT g.Name AS Genere,
       COUNT(t.TrackId)                           AS NumBrani,
       ROUND(AVG(t.Milliseconds) / 1000, 1)     AS DurataMediaSec
FROM Track t
JOIN Genre g ON t.GenreId = g.GenreId
GROUP BY g.GenreId, g.Name
ORDER BY DurataMediaSec DESC;


# --> 11.Track più costosa e più economica per genere

SELECT g.Name,
       MIN(t.UnitPrice) AS Minimo,
       MAX(t.UnitPrice) AS Massimo
FROM Track t
JOIN Genre g ON t.GenreId = g.GenreId
GROUP BY g.GenreId, g.Name;

# --> 12. Artisti con più di 10 brani venduti (totale quantità)
Catena completa Artist→Album→Track→InvoiceLine, con SUM(Quantity).

SELECT ar.Name, SUM(il.Quantity) AS BraniVenduti
FROM Artist       ar
JOIN Album        al ON ar.ArtistId = al.ArtistId
JOIN Track        t  ON al.AlbumId  = t.AlbumId
JOIN InvoiceLine  il ON t.TrackId   = il.TrackId
GROUP BY ar.ArtistId, ar.Name
HAVING SUM(il.Quantity) > 10
ORDER BY BraniVenduti DESC;

# --> 13. Generi con più di 100 brani
HAVING con COUNT — la distinzione WHERE vs HAVING è una delle domande orali più frequenti.

SELECT g.Name, COUNT(t.TrackId) AS NumBrani
FROM Genre g
JOIN Track t ON g.GenreId = t.GenreId
GROUP BY g.GenreId, g.Name
HAVING COUNT(t.TrackId) > 100
ORDER BY NumBrani DESC;

# --> 14. Clienti che hanno speso più di 40€ in totale
SUM(Total) con HAVING. Combina WHERE su date e HAVING su aggregato.

SELECT c.FirstName, c.LastName,
       ROUND(SUM(i.Total), 2) AS TotaleSpeso
FROM Customer c
JOIN Invoice  i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId
HAVING SUM(i.Total) > 40
ORDER BY TotaleSpeso DESC;

# --> 15. Playlist con almeno 15 brani
SELECT p.Name, COUNT(pt.TrackId) AS NumBrani
FROM Playlist      p
JOIN PlaylistTrack pt ON p.PlaylistId = pt.PlaylistId
GROUP BY p.PlaylistId, p.Name
HAVING COUNT(pt.TrackId) >= 15
ORDER BY NumBrani DESC;


# --> 16.-- Versione "quanti artisti di quel genere" (dalla tua simulazione)
SELECT COUNT(DISTINCT a.ArtistId) AS ArtistitiRock
FROM Artist a
JOIN Album  al ON a.ArtistId = al.ArtistId
JOIN Track  t  ON al.AlbumId  = t.AlbumId
JOIN Genre  g  ON t.GenreId   = g.GenreId
WHERE g.Name = 'Rock';

         -- Con quante vendite (Q02 del tuo test)
SELECT COUNT(DISTINCT a.ArtistId) AS ArtistitiRockVenduti
FROM Artist       a
JOIN Album        al ON a.ArtistId  = al.ArtistId
JOIN Track        t  ON al.AlbumId  = t.AlbumId
JOIN Genre        g  ON t.GenreId   = g.GenreId
JOIN InvoiceLine  il ON t.TrackId   = il.TrackId
WHERE g.Name = 'Rock';

# --> 17.Track con prezzo superiore alla media
SELECT Name, UnitPrice
FROM Track
WHERE UnitPrice > (
    SELECT AVG(UnitPrice)
    FROM Track
)
ORDER BY UnitPrice DESC;

# --> 18. Artisti che non hanno mai venduto (NOT EXISTS)
NOT EXISTS è spesso più efficiente di NOT IN quando la subquery può restituire NULL.

SELECT ar.Name
FROM Artist ar
WHERE NOT EXISTS (
    SELECT 1
    FROM Album       al
    JOIN Track       t  ON al.AlbumId = t.AlbumId
    JOIN InvoiceLine il ON t.TrackId  = il.TrackId
    WHERE al.ArtistId = ar.ArtistId
)
ORDER BY ar.Name;

# --> 19.Top spender per paese (subquery correlata)
Per ogni paese, trova il cliente che ha speso di più. Subquery correlata classica.

SELECT c.Country, c.FirstName, c.LastName,
       SUM(i.Total) AS TotaleSpeso
FROM Customer c
JOIN Invoice  i ON c.CustomerId = i.CustomerId
GROUP BY c.Country, c.CustomerId
HAVING SUM(i.Total) = (
    SELECT MAX(SUM(i2.Total))
    FROM Customer c2
    JOIN Invoice  i2 ON c2.CustomerId = i2.CustomerId
    WHERE c2.Country = c.Country
    GROUP BY c2.CustomerId
)
ORDER BY c.Country;


# --> 20. Derived table: fatturato medio per mese (media di tutti i periodi)

SELECT AVG(sub.TotaleMensile) AS MediaMensile
FROM (
    SELECT DATE_FORMAT(InvoiceDate, '%Y-%m') AS Mese,
           SUM(Total) AS TotaleMensile
    FROM Invoice
    GROUP BY Mese
) AS sub;


# --> 21. Popolarità artisti per genere (dalla simulazione)
Questa è la query get_artist_track del tuo DAO.py. Fondamentale per il grafo.

SELECT a.ArtistId, a.Name,
       i.CustomerId,
       SUM(il.Quantity) AS QtVenduta
FROM       Artist      a
JOIN       Album       al  ON a.ArtistId  = al.ArtistId
JOIN       Track       tr  ON al.AlbumId  = tr.AlbumId
JOIN       Genre       gen ON tr.GenreId  = gen.GenreId
JOIN       InvoiceLine il  ON tr.TrackId  = il.TrackId
JOIN       Invoice     i   ON il.InvoiceId = i.InvoiceId
WHERE gen.Name = 'Rock'
GROUP BY a.ArtistId, a.Name, i.CustomerId
ORDER BY a.Name;
📌 Simulazione: Questa query alimenta il grafo diretto. Ogni coppia (artista, cliente) forma un arco potenziale.
L'arco si crea se e solo se il cliente ha acquistato almeno un brano di quell'artista (ovvero se la coppia ArtistId, CustomerId compare nei risultati della query).


# --> 22. Top 10 brani più venduti
SELECT t.Name AS Brano,
       ar.Name AS Artista,
       SUM(il.Quantity) AS CopieVendute
FROM Track        t
JOIN Album        al ON t.AlbumId    = al.AlbumId
JOIN Artist       ar ON al.ArtistId  = ar.ArtistId
JOIN InvoiceLine  il ON t.TrackId    = il.TrackId
GROUP BY t.TrackId, t.Name, ar.Name
ORDER BY CopieVendute DESC
LIMIT 10;

# --> 23. Revenue per dipendente di supporto, non considera i capi (a meno che un capo non faccia anche direttamente da supporto a qualche cliente).
Quante vendite ha generato ogni sales rep? Employee→Customer→Invoice.
SELECT e.FirstName, e.LastName,
       COUNT(DISTINCT c.CustomerId) AS NumClienti,
       ROUND(SUM(i.Total), 2)       AS TotaleGenerato
FROM Employee e
JOIN Customer c ON e.EmployeeId = c.SupportRepId
JOIN Invoice  i ON c.CustomerId = i.CustomerId
GROUP BY e.EmployeeId
ORDER BY TotaleGenerato DESC;

# --> 24. UNION: email di clienti e dipendenti
SELECT Email, 'Customer' AS Tipo
FROM Customer
UNION
SELECT Email, 'Employee' AS Tipo
FROM Employee
ORDER BY Email;
UNION vs UNION ALL: UNION elimina duplicati (più lento), UNION ALL li mantiene.

# --> 25. Clienti comuni tra due artisti
Questa è la logica degli archi del grafo: clienti che hanno comprato da ENTRAMBI gli artisti.

-- Clienti che hanno comprato sia da Led Zeppelin che da Metallica
SELECT c.CustomerId, c.FirstName, c.LastName
FROM Customer c
WHERE c.CustomerId IN (
    SELECT i.CustomerId
    FROM Artist ar
    JOIN Album       al ON ar.ArtistId = al.ArtistId
    JOIN Track       t  ON al.AlbumId  = t.AlbumId
    JOIN InvoiceLine il ON t.TrackId   = il.TrackId
    JOIN Invoice     i  ON il.InvoiceId = i.InvoiceId
    WHERE ar.Name = 'Led Zeppelin'
)
AND c.CustomerId IN (
    SELECT i.CustomerId
    FROM Artist ar
    JOIN Album       al ON ar.ArtistId = al.ArtistId
    JOIN Track       t  ON al.AlbumId  = t.AlbumId
    JOIN InvoiceLine il ON t.TrackId   = il.TrackId
    JOIN Invoice     i  ON il.InvoiceId = i.InvoiceId
    WHERE ar.Name = 'Metallica'
);

# --> 26. EXCEPT simulato: artisti Rock mai comprati da italiani
DIFFICILE
SELECT DISTINCT ar.Name
FROM Artist ar
JOIN Album  al ON ar.ArtistId = al.ArtistId
JOIN Track  t  ON al.AlbumId  = t.AlbumId
JOIN Genre  g  ON t.GenreId   = g.GenreId
WHERE g.Name = 'Rock'
AND ar.ArtistId NOT IN (
    SELECT DISTINCT ar2.ArtistId
    FROM Artist       ar2
    JOIN Album        al2 ON ar2.ArtistId  = al2.ArtistId
    JOIN Track        t2  ON al2.AlbumId  = t2.AlbumId
    JOIN InvoiceLine  il  ON t2.TrackId   = il.TrackId
    JOIN Invoice      i   ON il.InvoiceId = i.InvoiceId
    JOIN Customer     c   ON i.CustomerId = c.CustomerId
    WHERE c.Country = 'Italy'
);

# --> 27.Ranking artisti per vendite (RANK)
SELECT ar.Name,
       SUM(il.Quantity) AS TotVendute,
       RANK() OVER (ORDER BY SUM(il.Quantity) DESC) AS Posizione
FROM Artist       ar
JOIN Album        al ON ar.ArtistId = al.ArtistId
JOIN Track        t  ON al.AlbumId  = t.AlbumId
JOIN InvoiceLine  il ON t.TrackId   = il.TrackId
GROUP BY ar.ArtistId, ar.Name
ORDER BY Posizione;

# --> 28. Top 1 artista per genere (RANK + partizione)
SELECT Genere, Artista, TotVendute
FROM (
    SELECT g.Name  AS Genere,
           ar.Name AS Artista,
           SUM(il.Quantity) AS TotVendute,
           RANK() OVER (
               PARTITION BY g.GenreId
               ORDER BY SUM(il.Quantity) DESC
           ) AS rk
    FROM Artist       ar
    JOIN Album        al ON ar.ArtistId = al.ArtistId
    JOIN Track        t  ON al.AlbumId  = t.AlbumId
    JOIN Genre        g  ON t.GenreId   = g.GenreId
    JOIN InvoiceLine  il ON t.TrackId   = il.TrackId
    GROUP BY g.GenreId, g.Name, ar.ArtistId, ar.Name
) AS ranked
WHERE rk = 1
ORDER BY Genere;
RANK vs DENSE_RANK: RANK salta numeri dopo ex-aequo (1,2,2,4). DENSE_RANK no (1,2,2,3).

# --> 29. Quanti sottoposti ha ogni manager?
    e2.FirstName AS NomeCapo,
    e2.LastName AS CognomeCapo,
    COUNT(e1.EmployeeId) AS NumeroSottoposti
FROM Employee e1, Employee e2
WHERE e1.ReportsTo = e2.EmployeeId
GROUP BY e2.EmployeeId, e2.FirstName, e2.LastName
ORDER BY NumeroSottoposti DESC

# --> 30. Mostra TUTTI i dipendenti (compreso il grande capo) e, SE ce l'hanno, il nome del loro manager.
SELECT
    e1.FirstName AS Dipendente,
    e2.FirstName AS Capo
FROM Employee e1
LEFT JOIN Employee e2 ON e1.ReportsTo = e2.EmployeeId

# ==============================================================================
# 🎸 CHINOOK (Base) - NODI
# ==============================================================================


# ---> 1. ARCHI: Artisti nella stessa Playlist
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

# ---> 2. Nodi del grafo: tutti artisti di un genere
Corrisponde a get_vertici(genere) nel DAO.

SELECT DISTINCT a.ArtistId, a.Name
FROM Artist a
JOIN Album  al ON a.ArtistId = al.ArtistId
JOIN Track  t  ON al.AlbumId  = t.AlbumId
JOIN Genre  g  ON t.GenreId   = g.GenreId
WHERE g.Name = 'Rock'
ORDER BY a.Name;

# ---> 4. Artista più influente (peso uscenti - entranti)
In Python il modello calcola: influenza = peso_uscenti - peso_entranti. In SQL è possibile ma complesso — domanda orale tipica: "come lo faresti in SQL?"
-- Versione SQL (per capire la logica, non la query esatta del DAO)
-- Presuppone una vista/tabella "archi" con (artista_da, artista_a, peso)
WITH ArcPops AS (
    SELECT a.ArtistId, a.Name,
           COALESCE(SUM(il.Quantity), 0) AS Pop
    FROM Artist       a
    JOIN Album        al ON a.ArtistId  = al.ArtistId
    JOIN Track        t  ON al.AlbumId  = t.AlbumId
    JOIN Genre        g  ON t.GenreId   = g.GenreId
    JOIN InvoiceLine  il ON t.TrackId   = il.TrackId
    WHERE g.Name = 'Rock'
    GROUP BY a.ArtistId, a.Name
)
-- L'artista più "popolare" nel genere (massima pop) è quello che
-- nel grafo ha più archi uscenti, quindi massima influenza
SELECT Name, Pop
FROM ArcPops
ORDER BY Pop DESC
LIMIT 1;


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

# ==============================================================================
# 💡 TEMPLATE DAO ARCHI e PESO
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
# ==============================================================================
# Archi = Coppie di Clienti (Customer) che hanno comprato almeno una traccia in comune
SELECT DISTINCT c1.CustomerId AS Cliente1, c2.CustomerId AS Cliente2, il1.TrackId
FROM Invoice i1, InvoiceLine il1, Customer c1,
     Invoice i2, InvoiceLine il2, Customer c2
WHERE i1.InvoiceId = il1.InvoiceId
  AND i1.CustomerId = c1.CustomerId
  AND i2.InvoiceId = il2.InvoiceId
  AND i2.CustomerId = c2.CustomerId
  AND il1.TrackId = il2.TrackId
  AND c1.CustomerId < c2.CustomerId

# ==============================================================================
Archi = Coppie di Tracce acquistate insieme nella stessa Fattura (Invoice)
SELECT il1.TrackId AS Traccia1, il2.TrackId AS Traccia2, COUNT(*) AS VolteComprateInsieme
FROM InvoiceLine il1, InvoiceLine il2
WHERE il1.InvoiceId = il2.InvoiceId
  AND il1.TrackId < il2.TrackId
GROUP BY il1.TrackId, il2.TrackId

# ==============================================================================
Arco tra due clienti se hanno acquistato lo stesso artista
SELECT c1.CustomerId AS id1, c2.CustomerId AS id2, COUNT(DISTINCT ar.ArtistId) AS peso
FROM customer c1, invoice i1, invoiceline il1, track t1, album al1, artist ar,
     customer c2, invoice i2, invoiceline il2, track t2, album al2
WHERE c1.CustomerId = i1.CustomerId
AND i1.InvoiceId = il1.InvoiceId
AND il1.TrackId = t1.TrackId
AND t1.AlbumId = al1.AlbumId
AND al1.ArtistId = ar.ArtistId

AND c2.CustomerId = i2.CustomerId
AND i2.InvoiceId = il2.InvoiceId
AND il2.TrackId = t2.TrackId
AND t2.AlbumId = al2.AlbumId
AND al2.ArtistId = ar.ArtistId

AND c1.CustomerId < c2.CustomerId

GROUP BY c1.CustomerId, c2.CustomerId

# ==============================================================================

Arco orientato cliente A → cliente B se A compra prima di B
SELECT DISTINCT c1.CustomerId AS id1, c2.CustomerId AS id2
FROM customer c1, invoice i1,
     customer c2, invoice i2
WHERE c1.CustomerId = i1.CustomerId
AND c2.CustomerId = i2.CustomerId
AND c1.CustomerId <> c2.CustomerId
AND i1.InvoiceDate < i2.InvoiceDate
# ==============================================================================

# ---> 2. ARCHI: Artisti comprati dallo stesso Cliente (Uso della CTE 'WITH')
 "Il peso dell'arco tra l'artista A e l'artista B è pari al numero di clienti che hanno acquistato brani di entrambi"
# Se il cliente 12 e il cliente 45 hanno comprato sia i dischi degli U2 (ar1) che degli AC/DC (ar2), il database conterà quei 2 clienti distinti.
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
# ==============================================================================
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
Arco tra due clienti se hanno acquistato almeno un artista in comune
Peso = numero di artisti in comune.

SELECT q1.CustomerId AS idA,
       q2.CustomerId AS idB,
       COUNT(DISTINCT q1.ArtistId) AS peso
FROM (
    SELECT DISTINCT c.CustomerId, ar.ArtistId
    FROM customer c, invoice i, invoiceline il, track t, album al, artist ar
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
      AND t.AlbumId = al.AlbumId
      AND al.ArtistId = ar.ArtistId
) q1,
(
    SELECT DISTINCT c.CustomerId, ar.ArtistId
    FROM customer c, invoice i, invoiceline il, track t, album al, artist ar
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
      AND t.AlbumId = al.AlbumId
      AND al.ArtistId = ar.ArtistId
) q2
WHERE q1.CustomerId < q2.CustomerId
  AND q1.ArtistId = q2.ArtistId
GROUP BY q1.CustomerId, q2.CustomerId
# ==============================================================================
Arco tra due artisti se sono stati acquistati dallo stesso cliente

Peso = numero di clienti che hanno acquistato entrambi gli artisti.

SELECT q1.ArtistId AS idA,
       q2.ArtistId AS idB,
       COUNT(DISTINCT q1.CustomerId) AS peso
FROM (
    SELECT DISTINCT c.CustomerId, ar.ArtistId
    FROM customer c, invoice i, invoiceline il, track t, album al, artist ar
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
      AND t.AlbumId = al.AlbumId
      AND al.ArtistId = ar.ArtistId
) q1,
(
    SELECT DISTINCT c.CustomerId, ar.ArtistId
    FROM customer c, invoice i, invoiceline il, track t, album al, artist ar
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
      AND t.AlbumId = al.AlbumId
      AND al.ArtistId = ar.ArtistId
) q2
WHERE q1.ArtistId < q2.ArtistId
  AND q1.CustomerId = q2.CustomerId
GROUP BY q1.ArtistId, q2.ArtistId
# ==============================================================================
3. Nodi = album
Arco tra due album se sono stati acquistati dallo stesso cliente

Peso = numero di clienti che hanno acquistato entrambi gli album.

SELECT q1.AlbumId AS idA,
       q2.AlbumId AS idB,
       COUNT(DISTINCT q1.CustomerId) AS peso
FROM (
    SELECT DISTINCT c.CustomerId, al.AlbumId
    FROM customer c, invoice i, invoiceline il, track t, album al
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
      AND t.AlbumId = al.AlbumId
) q1,
(
    SELECT DISTINCT c.CustomerId, al.AlbumId
    FROM customer c, invoice i, invoiceline il, track t, album al
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
      AND t.AlbumId = al.AlbumId
) q2
WHERE q1.AlbumId < q2.AlbumId
  AND q1.CustomerId = q2.CustomerId
GROUP BY q1.AlbumId, q2.AlbumId
# ==============================================================================
4. Nodi = tracce
Arco tra due tracce se compaiono nella stessa fattura

Peso = numero di fatture in cui le due tracce sono state acquistate insieme.

SELECT q1.TrackId AS idA,
       q2.TrackId AS idB,
       COUNT(DISTINCT q1.InvoiceId) AS peso
FROM (
    SELECT DISTINCT il.InvoiceId, t.TrackId
    FROM invoiceline il, track t
    WHERE il.TrackId = t.TrackId
) q1,
(
    SELECT DISTINCT il.InvoiceId, t.TrackId
    FROM invoiceline il, track t
    WHERE il.TrackId = t.TrackId
) q2
WHERE q1.TrackId < q2.TrackId
  AND q1.InvoiceId = q2.InvoiceId
GROUP BY q1.TrackId, q2.TrackId

Nel grafo:

Traccia A -- Traccia B
peso = quante volte sono state comprate nella stessa fattura

Questa è molto bella perché sfrutta bene:

Invoice -> InvoiceLine -> Track
# ==============================================================================
5. Nodi = generi
Arco tra due generi se sono stati acquistati dallo stesso cliente

Peso = numero di clienti che hanno acquistato entrambi i generi.

SELECT q1.GenreId AS idA,
       q2.GenreId AS idB,
       COUNT(DISTINCT q1.CustomerId) AS peso
FROM (
    SELECT DISTINCT c.CustomerId, g.GenreId
    FROM customer c, invoice i, invoiceline il, track t, genre g
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
      AND t.GenreId = g.GenreId
) q1,
(
    SELECT DISTINCT c.CustomerId, g.GenreId
    FROM customer c, invoice i, invoiceline il, track t, genre g
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
      AND t.GenreId = g.GenreId
) q2
WHERE q1.GenreId < q2.GenreId
  AND q1.CustomerId = q2.CustomerId
GROUP BY q1.GenreId, q2.GenreId

Nel grafo:

Genere A -- Genere B
peso = clienti che hanno ascoltato/comprato entrambi
# ==============================================================================
6. Nodi = paesi
Arco tra due paesi se clienti di quei paesi hanno acquistato almeno un artista in comune

Peso = numero di artisti acquistati in entrambi i paesi.

SELECT q1.Country AS idA,
       q2.Country AS idB,
       COUNT(DISTINCT q1.ArtistId) AS peso
FROM (
    SELECT DISTINCT c.Country, ar.ArtistId
    FROM customer c, invoice i, invoiceline il, track t, album al, artist ar
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
      AND t.AlbumId = al.AlbumId
      AND al.ArtistId = ar.ArtistId
) q1,
(
    SELECT DISTINCT c.Country, ar.ArtistId
    FROM customer c, invoice i, invoiceline il, track t, album al, artist ar
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
      AND t.AlbumId = al.AlbumId
      AND al.ArtistId = ar.ArtistId
) q2
WHERE q1.Country < q2.Country
  AND q1.ArtistId = q2.ArtistId
GROUP BY q1.Country, q2.Country
# ==============================================================================
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
2. Peso = numero di tracce comuni tra due clienti

Questo caso esce quando i nodi sono, per esempio:

Clienti
Fatture
Album
Playlist, se ci fosse

Esempio:

Nodo A = Cliente 1
Nodo B = Cliente 2
Peso = numero di tracce acquistate da entrambi

Query:

SELECT q1.CustomerId AS idA,
       q2.CustomerId AS idB,
       COUNT(DISTINCT q1.TrackId) AS peso
FROM (
    SELECT DISTINCT c.CustomerId, t.TrackId
    FROM customer c, invoice i, invoiceline il, track t
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
) q1,
(
    SELECT DISTINCT c.CustomerId, t.TrackId
    FROM customer c, invoice i, invoiceline il, track t
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
) q2
WHERE q1.CustomerId < q2.CustomerId
  AND q1.TrackId = q2.TrackId
GROUP BY q1.CustomerId, q2.CustomerId

# ==============================================================================

Se due clienti hanno acquistato la stessa traccia, metto arco.
Peso = COUNT(DISTINCT TrackId)
3. Peso = somma quantità acquistate
Qui devi usare:
SUM(il.Quantity)
oppure, se devi sommare la quantità di due nodi collegati:

SUM(q1.Quantity + q2.Quantity)

Esempio:

Nodi = clienti
Arco tra due clienti se hanno acquistato la stessa traccia
Peso = quantità totale acquistata dai due clienti su quelle tracce comuni

Query:

SELECT q1.CustomerId AS idA,
       q2.CustomerId AS idB,
       SUM(q1.qta + q2.qta) AS peso
FROM (
    SELECT c.CustomerId,
           t.TrackId,
           SUM(il.Quantity) AS qta
    FROM customer c, invoice i, invoiceline il, track t
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
    GROUP BY c.CustomerId, t.TrackId
) q1,
(
    SELECT c.CustomerId,
           t.TrackId,
           SUM(il.Quantity) AS qta
    FROM customer c, invoice i, invoiceline il, track t
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
    GROUP BY c.CustomerId, t.TrackId
) q2
WHERE q1.CustomerId < q2.CustomerId
  AND q1.TrackId = q2.TrackId
GROUP BY q1.CustomerId, q2.CustomerId

Formula mentale:

Prima calcolo quanto ogni nodo ha comprato.
Poi confronto due nodi.
Se hanno qualcosa in comune, sommo le quantità.

# ==============================================================================
4. Peso = somma importi

Qui la formula sicura è:

SUM(il.UnitPrice * il.Quantity)

Questa è importantissima.

Quando sei dentro invoiceline, non usare quasi mai:

SUM(i.Total)

perché rischi di sommare più volte la stessa fattura.

Caso semplice: spesa totale di un cliente
SELECT c.CustomerId,
       SUM(il.UnitPrice * il.Quantity) AS spesa
FROM customer c, invoice i, invoiceline il
WHERE c.CustomerId = i.CustomerId
  AND i.InvoiceId = il.InvoiceId
GROUP BY c.CustomerId
Peso arco = spesa comune tra due clienti sugli stessi artisti

Esempio:

Nodi = clienti
Arco se due clienti hanno acquistato lo stesso artista
Peso = somma della spesa dei due clienti sugli artisti comuni
SELECT q1.CustomerId AS idA,
       q2.CustomerId AS idB,
       SUM(q1.spesa + q2.spesa) AS peso
FROM (
    SELECT c.CustomerId,
           ar.ArtistId,
           SUM(il.UnitPrice * il.Quantity) AS spesa
    FROM customer c, invoice i, invoiceline il, track t, album al, artist ar
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
      AND t.AlbumId = al.AlbumId
      AND al.ArtistId = ar.ArtistId
    GROUP BY c.CustomerId, ar.ArtistId
) q1,
(
    SELECT c.CustomerId,
           ar.ArtistId,
           SUM(il.UnitPrice * il.Quantity) AS spesa
    FROM customer c, invoice i, invoiceline il, track t, album al, artist ar
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
      AND t.AlbumId = al.AlbumId
      AND al.ArtistId = ar.ArtistId
    GROUP BY c.CustomerId, ar.ArtistId
) q2
WHERE q1.CustomerId < q2.CustomerId
  AND q1.ArtistId = q2.ArtistId
GROUP BY q1.CustomerId, q2.CustomerId

Formula mentale:

Importo riga = UnitPrice * Quantity
Peso arco = SUM(importi)

Trappola:

SUM(i.Total)

è pericoloso se hai fatto join con invoiceline.
# ==============================================================================
5. Peso = differenza tra date

Questo caso serve nei grafi orientati.

Esempio:

Nodo A = fattura precedente
Nodo B = fattura successiva
Arco A -> B se A avviene prima di B
Peso = giorni tra le due fatture

Si usa:

DATEDIFF(data2, data1)

Query:

SELECT i1.InvoiceId AS idA,
       i2.InvoiceId AS idB,
       DATEDIFF(i2.InvoiceDate, i1.InvoiceDate) AS peso
FROM invoice i1, invoice i2
WHERE i1.InvoiceId <> i2.InvoiceId
  AND i1.InvoiceDate < i2.InvoiceDate

Se vuoi solo archi entro massimo K giorni:

SELECT i1.InvoiceId AS idA,
       i2.InvoiceId AS idB,
       DATEDIFF(i2.InvoiceDate, i1.InvoiceDate) AS peso
FROM invoice i1, invoice i2
WHERE i1.InvoiceId <> i2.InvoiceId
  AND i1.InvoiceDate < i2.InvoiceDate
  AND DATEDIFF(i2.InvoiceDate, i1.InvoiceDate) <= %s

Formula mentale:

Grafo orientato temporale:
A -> B
se dataA < dataB

peso = DATEDIFF(dataB, dataA)

Attenzione all’ordine:

DATEDIFF(i2.InvoiceDate, i1.InvoiceDate)

significa:

data finale - data iniziale

# ==============================================================================
6. Peso = numero di fatture comuni

Questo caso esce quando due nodi compaiono nella stessa fattura.

Esempio:

Nodi = tracce
Arco tra due tracce se sono state comprate nella stessa fattura
Peso = numero di fatture in cui compaiono insieme

Query:

SELECT q1.TrackId AS idA,
       q2.TrackId AS idB,
       COUNT(DISTINCT q1.InvoiceId) AS peso
FROM (
    SELECT DISTINCT il.InvoiceId, il.TrackId
    FROM invoiceline il
) q1,
(
    SELECT DISTINCT il.InvoiceId, il.TrackId
    FROM invoiceline il
) q2
WHERE q1.TrackId < q2.TrackId
  AND q1.InvoiceId = q2.InvoiceId
GROUP BY q1.TrackId, q2.TrackId

Formula mentale:

Traccia - Fattura
Traccia - Fattura

Se due tracce stanno nella stessa fattura, metto arco.
Peso = COUNT(DISTINCT InvoiceId)

# ==============================================================================
7. Peso = numero di album comuni

Questo caso esce quando i nodi sono clienti, artisti o generi.

Esempio:

Nodi = clienti
Arco tra due clienti se hanno acquistato album comuni
Peso = numero di album acquistati da entrambi

Query:

SELECT q1.CustomerId AS idA,
       q2.CustomerId AS idB,
       COUNT(DISTINCT q1.AlbumId) AS peso
FROM (
    SELECT DISTINCT c.CustomerId, al.AlbumId
    FROM customer c, invoice i, invoiceline il, track t, album al
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
      AND t.AlbumId = al.AlbumId
) q1,
(
    SELECT DISTINCT c.CustomerId, al.AlbumId
    FROM customer c, invoice i, invoiceline il, track t, album al
    WHERE c.CustomerId = i.CustomerId
      AND i.InvoiceId = il.InvoiceId
      AND il.TrackId = t.TrackId
      AND t.AlbumId = al.AlbumId
) q2
WHERE q1.CustomerId < q2.CustomerId
  AND q1.AlbumId = q2.AlbumId
GROUP BY q1.CustomerId, q2.CustomerId

Formula mentale:

Cliente - Album
Cliente - Album
# ==============================================================================
Se due clienti hanno acquistato lo stesso album, metto arco.
Peso = COUNT(DISTINCT AlbumId)
Tabella riassuntiva pesi
Peso richiesto	Cosa uso in SQL
Numero clienti comuni	COUNT(DISTINCT CustomerId)
Numero tracce comuni	COUNT(DISTINCT TrackId)
Numero artisti comuni	COUNT(DISTINCT ArtistId)
Numero album comuni	COUNT(DISTINCT AlbumId)
Numero fatture comuni	COUNT(DISTINCT InvoiceId)
Quantità acquistata	SUM(il.Quantity)
Importo acquistato	SUM(il.UnitPrice * il.Quantity)
Differenza tra date	DATEDIFF(dataFinale, dataIniziale)
Prima data	MIN(InvoiceDate)
Ultima data	MAX(InvoiceDate)
Media spesa	AVG(il.UnitPrice * il.Quantity)
La regola più importante

Quando il peso è un numero di elementi comuni, usi quasi sempre:

COUNT(DISTINCT elementoComune)

Esempi:

COUNT(DISTINCT c.CustomerId)
COUNT(DISTINCT t.TrackId)
COUNT(DISTINCT al.AlbumId)
COUNT(DISTINCT ar.ArtistId)
COUNT(DISTINCT i.InvoiceId)

Quando il peso è una quantità, usi:

SUM(il.Quantity)

Quando il peso è una spesa, usi:

SUM(il.UnitPrice * il.Quantity)

Quando il peso è una distanza temporale, usi:

DATEDIFF(data2, data1)
Schema universale da adattare domani

Questa è la query madre:

SELECT q1.idNodo AS idA,
       q2.idNodo AS idB,
       COUNT(DISTINCT q1.elementoComune) AS peso
FROM (
    SELECT DISTINCT nodo AS idNodo,
                    elementoComune
    FROM ...
    WHERE ...
) q1,
(
    SELECT DISTINCT nodo AS idNodo,
                    elementoComune
    FROM ...
    WHERE ...
) q2
WHERE q1.idNodo < q2.idNodo
  AND q1.elementoComune = q2.elementoComune
GROUP BY q1.idNodo, q2.idNodo

Devi solo sostituire:

idNodo = il tipo di nodo del grafo
elementoComune = la cosa che crea il collegamento
peso = cosa chiede la traccia

Esempi:

Nodi clienti, elemento comune artista
=> peso = COUNT(DISTINCT ArtistId)

Nodi artisti, elemento comune cliente
=> peso = COUNT(DISTINCT CustomerId)

Nodi tracce, elemento comune fattura
=> peso = COUNT(DISTINCT InvoiceId)

Nodi clienti, elemento comune album
=> peso = COUNT(DISTINCT AlbumId)


# ==============================================================================
# 🎸 CHINOOK - SOLO PESO
# ==============================================================================

# ---> 3. Popolarità artista (peso nodo)
Totale quantità venduta per artista nel genere. Il peso dell'arco nel grafo è pop(u)+pop(v).

SELECT a.ArtistId, a.Name,
       SUM(il.Quantity) AS Popolarita
FROM Artist       a
JOIN Album        al ON a.ArtistId  = al.ArtistId
JOIN Track        t  ON al.AlbumId  = t.AlbumId
JOIN Genre        g  ON t.GenreId   = g.GenreId
JOIN InvoiceLine  il ON t.TrackId   = il.TrackId
WHERE g.Name = 'Rock'
GROUP BY a.ArtistId, a.Name
ORDER BY Popolarita DESC;