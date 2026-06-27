#GRAFO DIRETTO PESATO
def buildGraph(self, categoria, data1, data2):
    self._graph.clear()
    self._idMapNodi = {p.product_id: p for p in self._DAO.get_nodes(categoria)}
    listaEdges = self._DAO.get_edges(categoria, data1, data2)
    for prod in self._idMapNodi.values():
        self._graph.add_node(prod)
    for id1, vendite1 in listaEdges:
        for id2, vendite2 in listaEdges:
            if id1 < id2:
                nodo1 = self._idMapNodi.get(id1)
                nodo2 = self._idMapNodi.get(id2)

                if nodo1 is not None and nodo2 is not None:
                    peso = int(vendite1) + int(vendite2)
                    if vendite1 < vendite2:
                        self._graph.add_edge(nodo1, nodo2, weight=peso)
                    elif vendite1 > vendite2:
                        self._graph.add_edge(nodo2, nodo1, weight=peso)
                    else:
                        self._graph.add_edge(nodo1, nodo2, weight=peso)
                        self._graph.add_edge(nodo2, nodo1, weight=peso)
#-------------------------------------------------------------------
#MIGLIORI 5 ARCHI
def get_top5_archi(self):
    lista_archi = []

    # grafo.edges(data=True) restituisce una tupla di 3 elementi per ogni arco:
    # (nodo_partenza, nodo_arrivo, dizionario_degli_attributi)
    # Esempio: ('A', 'B', {'weight': 15})
    for u, v, dati in self._graph.edges(data=True):
        # Estraiamo il peso dal dizionario (se non c'è, diciamo che vale 0 di default)
        peso = dati.get('weight', 0)

        # Salviamo in una nostra lista una tupla personalizzata
        lista_archi.append((u, v, peso))

    # Ordiniamo la lista in base al peso.
    # Il peso si trova all'indice 2 della nostra tupla (u=0, v=1, peso=2)
    # reverse=True serve per avere i pesi più alti per primi (ordine decrescente)
    lista_archi.sort(key=lambda x: x[2], reverse=True)

    # Ritorniamo solo i primi 5 elementi
    return lista_archi[:5]
#-------------------------------------------------------------------
#MIGLIORI 5 NODI
def top5(self):
    lista = []
    for n in self._graph.nodes:
        # 3. Chiediamo a NetworkX di calcolare la somma dei pesi di tutti gli archi
        #    che ENTRANO nel nodo 'n'.
        #    (Nota: è fondamentale specificare weight='weight' altrimenti conta solo il numero di archi)
        peso_in = self._graph.in_degree(n, weight='weight')
        peso_out = self._graph.out_degree(n, weight='weight')
        score = peso_in - peso_out
        # 6. Inseriamo nella nostra lista una tupla contenente il nodo e il suo punteggio appena calcolato
        lista.append((n, score))


    lista.sort(key=lambda x: x[1], reverse=True)
    return lista[:5]
#-------------------------------------------------------------------
#QUANTI COLLEGAMENTI HA IL TUO NODO?
"""Caso 1: NON usi il parametro weight
Se scrivi semplicemente degree(nodo), in_degree(nodo) o out_degree(nodo): NetworkX si limita a CONTARE gli archi (1, 2, 3...). Non gli interessa
 se un arco ha un peso di 1000 e l'altro ha un peso di 2, per lui valgono sempre 1. È il classico conteggio delle connessioni.

Caso 2: USI il parametro weight='weight'
Se scrivi degree(nodo, weight='weight') (o gli altri due): NetworkX smette di contare gli archi e inizia a SOMMARE I LORO PESI.

in_degree(nodo, weight='weight'): Somma il valore numerico dei pesi di tutti gli archi che ENTRANO."""


def get_nodi_con_piu_collegamenti(self):
    lista_gradi = []

    for n in self._graph.nodes:
        # Conta il numero di archi collegati al nodo (Senza weight='weight' conta solo le quantità)
        # Usa out_degree(n) o in_degree(n) se ti interessa solo una direzione
        numero_collegamenti = self._graph.degree(n)

        lista_gradi.append((n, numero_collegamenti))

    # Ordina dal più grande al più piccolo in base al numero_collegamenti (indice 1)
    lista_gradi.sort(key=lambda x: x[1], reverse=True)

    return lista_gradi[:5]
#-------------------------------------------------------------------
#Calcolare e Ordinare per "Somma dei Pesi"
def get_top_nodi_per_peso(self):
    risultato = []
    for n in self._graph.nodes:
        # Aggiungendo weight='weight' esegue la SOMMA DEI PESI e non il conteggio degli archi
        peso_totale = self._graph.degree(n, weight='weight')
        risultato.append((n, peso_totale))

    risultato.sort(key=lambda x: x[1], reverse=True)
    return risultato[:5]
#-------------------------------------------------------------------
#Iterare le Coppie di Nodi Senza Duplicati
lista_oggetti = self._DAO.get_tutto()
for id1, obj1 in lista_oggetti:
    for id2, obj2 in lista_oggetti:
        # L'if evita di confrontare A con A, e scarta la coppia doppia B-A
        if id1 < id2:
            # ... fai calcoli sul peso ...
            peso = calcola_peso(obj1, obj2)
            if peso > 0:
                self._graph.add_edge(obj1, obj2, weight=peso)
#-------------------------------------------------------------------
#Nodi Raggiungibili (Componente Connessa)
def get_nodi_raggiungibili(self, nodo_partenza):
    # Restituisce il "grappolo" di nodi connessi a quello di partenza
    componente = nx.node_connected_component(self._graph, nodo_partenza)
    return list(componente)

# -------------------------------------------------------------------
#return tutti i vicini del nodo con (vicino,peso)
def getDettagli(self, squadra):
    if squadra not in self._graph.nodes:
        return []

    vicini = self._graph.neighbors(squadra)
    dettagli = []

    for vicino in vicini:
        peso = self._graph[squadra][vicino]['weight']
        dettagli.append((vicino, peso))

    dettagli.sort(key=lambda x: x[1], reverse=True)

    return dettagli
# ---------------------------------------------------------
# CASO 1: "Trova la componente connessa più grande (con più nodi)"

def get_componente_maggiore(self):
    # Recuperiamo tutte le componenti (sono come "isole" staccate)
    # nx.connected_components restituisce una lista di SET (insiemi) di nodi
    componenti = list(nx.connected_components(self._graph))

    # Usiamo max() con la chiave 'len' per trovare in automatico l'isola col maggior numero di nodi
    componente_maggiore = max(componenti, key=len)

    dimensione = len(componente_maggiore)
    print(f"La componente maggiore ha {dimensione} nodi.")

    return componente_maggiore

# ---------------------------------------------------------
# CASO 2: "Quanti nodi sono raggiungibili partendo da un NODO SPECIFICO?"
# (In pratica: "Dammi l'isola in cui si trova questo nodo")
def get_componente_di_un_nodo(self, nodo_partenza):
    # nx.node_connected_component tira fuori solo i nodi connessi a quello di partenza
    componente = nx.node_connected_component(self._graph, nodo_partenza)

    dimensione = len(componente)
    print(f"Dal nodo scelto puoi raggiungere altri {dimensione - 1} nodi.")

    # Se vuoi passarla al controller o stamparla, ti conviene trasformarla in lista
    return list(componente)

# ---------------------------------------------------------
# CASO 3: "Verifica se il grafo è tutto collegato, altrimenti dimmi quanti pezzi ci sono"

def analisi_connessione_globale(self):
    # Restituisce True se è un unico blocco, False se è spezzato in più parti
    is_connesso = nx.is_connected(self._graph)

    if is_connesso:
        print("Il grafo è interamente connesso! (Esiste solo 1 componente)")
    else:
        # Conta fisicamente in quante isole separate è diviso il grafo
        num_componenti = nx.number_connected_components(self._graph)
        print(f"Il grafo è spezzato in {num_componenti} componenti separate.")

# ---------------------------------------------------------
# CASO 4: "Calcola le dimensioni di tutte le componenti e stampale in ordine decrescente"

def classifica_componenti(self):
    componenti = list(nx.connected_components(self._graph))

    classifica = []
    for comp in componenti:
        # Salvo la dimensione e la componente stessa in una tupla
        classifica.append((len(comp), comp))

    # Ordino la classifica per la dimensione (indice 0 della tupla), dal più grande al più piccolo
    classifica.sort(key=lambda x: x[0], reverse=True)

    # Stampo il risultato
    for i, (dim, comp) in enumerate(classifica):
        print(f"Componente {i + 1}: {dim} nodi.")

    return classifica
# ATTENZIONE SUI GRAFI ORIENTATI (DiGraph):
# Nei grafi orientati le funzioni di base non funzionano.
# Se il prof ti chiede le componenti su un DiGraph, usa nx.weakly_connected_components(self._graph)
# (Tratta le strade a senso unico come se fossero a doppio senso).
#Fai finta che le frecce non contino nulla e che siano tutte strade a doppio senso. Dimmi solo chi è attaccato a chi"
# ---------------------------------------------------------
