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

#MIGLIORI 5 ARCHI
def get_top5_archi(grafo):
    lista_archi = []

    # grafo.edges(data=True) restituisce una tupla di 3 elementi per ogni arco:
    # (nodo_partenza, nodo_arrivo, dizionario_degli_attributi)
    # Esempio: ('A', 'B', {'weight': 15})
    for u, v, dati in grafo.edges(data=True):
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



