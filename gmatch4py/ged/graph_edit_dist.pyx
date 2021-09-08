# -*- coding: UTF-8 -*-

import sys

import networkx as nx
import numpy as np
cimport numpy as np


cdef class GraphEditDistance():

    def __init__(self,node_del,node_ins,edge_del,edge_ins,weighted=False):
        AbstractGraphEditDistance.__init__(self,node_del,node_ins,edge_del,edge_ins)
        self.weighted=weighted


    cpdef double sum_child(self,nodeGData):
        sum=0
        for i in range(1,len(nodeGData[0])):
            sum+=nodeGData[1][i]["weight"]
        return sum


    cpdef double child_ged(self,nodeGData,nodeHData):
        #TODO devo retonrare in matcher [nodo,peso], sommare i pesi dei matched e poi sottrato al somma di G o H in base a chi ha piu' nodi      
           
        cur_min=sys.maxsize
        cur_node=[]
        sumI=0
        matched={}

        for i in range(1,len(nodeGData[0])):
            _weightI=nodeGData[1][i]["weight"]
            sumI+=_weightI
            sumJ=0
            for j in range(1,len(nodeHData[0])):
                _weightJ=nodeHData[1][j]["weight"]
                sumJ+=_weightJ

                if(matched.has_key(nodeHData[0][j])):
                    #print("found an already matched node")
                    continue
                
                if(abs(_weightI-_weightJ)<cur_min):
                    cur_min=abs(_weightI-_weightJ)
                    cur_node=[nodeHData[0][j],nodeHData[1][j]["weight"]]
                    #print(cur_node)
                    
            cur_min=sys.maxsize
            if(cur_node!=[]):
                matched[cur_node[0]]=cur_node[1]
                cur_node=[]

        sum=0
        #print("matched:----")
        #print(matched)
        for node in matched:    
            #print(matched[node])
            sum+=matched[node]
        #print("matched:----")

        Gsize=len(nodeGData[0])
        Hsize=len(nodeHData[0])

        if(Gsize>Hsize):
            #print("G>H")
            return sumI-sum
        else:
            #print("G<H")
            return sumJ-sum



    cpdef double substitute_cost(self, node1, node2, G, H):
        
        #print("1")
        #print(G.nodes(data=True))
        #print("2")
        #print(G.nodes(data="weight"))
        #print("3")
        #print(G.nodes[node1]['weight'])
        #print("4")
        ## node1.weight - node2.weight + GED(figli)
        ##da testare ocn le print
        #print("G: ")
        #print(G)
        #print("G1: ")
        #G1=G.remove_node(node1)
        #print(G1)
        #H1=H.remove_node(node2)
        #res=self.father.compare([G1,H1],None)
        #self.compare([G1,H1],None)
        #print(self.distance_ged(G1,H1))


        
        nodeGData=list(G.nodes(data=True))
        _weightG= nodeGData[1][0]["weight"]
        nodeHData=list(H.nodes(data=True))
        _weightH= nodeHData[1][0]["weight"]

        #print("richiesto: " +  str(node1) + "il primo e' " + str(nodeGData[0][0]))

        #both root
        if(node1==nodeGData[0][0] and node2==nodeHData[0][0]):
            return abs(_weightG-_weightH)+self.child_ged(nodeGData,nodeHData)
        
        #both not root
        if(node1!=nodeGData[0][0] and node2!=nodeHData[0][0]):
            return abs(_weightG-_weightH)
        
        #node1 is a root but node2
        if(node1==nodeGData[0][0] and node2!=nodeHData[0][0]):
            return abs(_weightG-_weightH)+self.sum_child(nodeGData)
        
        #node2 is a root but node1
        if(node1!=nodeGData[0][0] and node2==nodeHData[0][0]):
            return abs(_weightG-_weightH)+self.sum_child(nodeHData)
        


        return abs(_weightG-_weightH)+self.child_ged(nodeGData,nodeHData)

        #return self.relabel_cost(node1, node2, G, H)

    cpdef object relabel_cost(self, node1, node2, G, H):
        #print("il costo deve essere il peso dei nodi")
        #print(node1)
        #nodesG=G.nodes()
        #cur_node=list(nodesG).index(node1)
        #print(cur_node)

        ## Si deux noeuds égaux
        if node1 == node2 and G.degree(node1) == H.degree(node2):
            return 0.0
        elif node1 == node2 and G.degree(node1) != H.degree(node2):
            #R = Graph(self.add_edges(node1,node2,G),G.get_node_key(),G.get_egde_key())
            #R2 = Graph(self.add_edges(node1,node2,H),H.get_node_key(),H.get_egde_key())
            #inter_= R.size_edge_intersect(R2)
            R=set(G.get_edges_no(node1))
            R2=set(H.get_edges_no(node2))
            inter_=R.intersection(R2)
            add_diff=abs(len(R2)-len(inter_))#abs(R2.density()-inter_)
            del_diff=abs(len(R)-len(inter_))#abs(R.density()-inter_)
            return (add_diff*self.edge_ins)+(del_diff*self.edge_del)


        #si deux noeuds connectés
        if  G.has_edge(node1,node2) or G.has_edge(node2,node1):
            return self.node_ins+self.node_del
        if not node2 in G.nodes():
            nodesH=H.nodes()
            index=list(nodesH).index(node2)
            return self.node_del+self.node_ins+self.insert_cost(index,index,nodesH,H)
        return sys.maxsize

    cdef double delete_cost(self, int i, int j, nodesG, G):
        #print("il costo deve essere zero_1")
        #print("nodo richiesto: " + str(nodesG[i]))
        #print(" ivale : "+ str(i))
        nodeGData=list(G.nodes(data=True))
        #print(nodeGData)
        _weight= nodeGData[1][i]["weight"]
        #print("il peso è: "+str(_weight))

        #return _weight+self.node_del+(G.degree(nodesG[i],weight=True)*self.edge_del)

        if i == j:
            return _weight+self.node_del+(G.degree(nodesG[i],weight=True)*self.edge_del) # Deleting a node implicate to delete in and out edges
        return sys.maxsize

    cdef double insert_cost(self, int i, int j, nodesH, H):
        #print("il costo deve essere zero_2")
        #print(nodesH[j])


        if i == j:
            nodeHData=list(H.nodes(data=True))
            _weight= nodeHData[1][j]["weight"]

            deg=H.degree(nodesH[j],weight=True)
            if isinstance(deg,dict):deg=0
            return _weight+self.node_ins+(deg*self.edge_ins)
        else:
            return sys.maxsize
