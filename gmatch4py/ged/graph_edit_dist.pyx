# -*- coding: UTF-8 -*-

import sys

import networkx as nx
import numpy as np
cimport numpy as np


cdef class GraphEditDistance():

    def __init__(self,node_del,node_ins,edge_del,edge_ins,weighted=False):
        AbstractGraphEditDistance.__init__(self,node_del,node_ins,edge_del,edge_ins)
        self.weighted=weighted

    cpdef double get_weight(self,node,nodeGData):
        _weight=0
        for i in range(0,len(nodeGData[0])):
            if(nodeGData[0][i]==node):
                _weight=nodeGData[1][i]["weight"]
                return _weight
        print("ERROR IN GET_WIGHT GRAPH_EDIT_DISTANCE.pyc")
        return _weight
        


    cpdef double sum_nodes(self,nodeGData):
        sum=0
        for i in range(0,len(nodeGData[0])):
            sum+=nodeGData[1][i]["weight"]
        return sum




    cpdef double sum_child(self,nodeGData):
        sum=0
        for i in range(1,len(nodeGData[0])):
            sum+=nodeGData[1][i]["weight"]
        return sum



    cpdef double delete_matched_node(self,ged_matrix,current_min_dict):
        for i in range(1,len(ged_matrix)+1):
            ged_matrix[i][current_min_dict[2]-1]=sys.maxsize
        return 0

    cpdef double get_min_from_dict(self,dest_dict,current_min_dict):
        cur_min=sys.maxsize
        for i in dest_dict:
            if(dest_dict[i][1]<cur_min and dest_dict[i][0]!=-1):
                cur_min=dest_dict[i][1]
                #print("new min fondued")
                #current_min_dict=[i,dest_dict[i][1],dest_dict[i][0]] #[node_x,ged,node_y]
                current_min_dict[0]=i
                current_min_dict[1]=dest_dict[i][1]
                current_min_dict[2]=dest_dict[i][0]

        if(cur_min==sys.maxsize):
            current_min_dict[0]=-1
            current_min_dict[1]=-1
            current_min_dict[2]=-1
        return 0

    cpdef double gen_min_dict(self,ged_matrix,dest_dict,matched):
        #dest_dict[x1]=[y_#,ged]
        #dest_dict[x2]=[y_#,ged]
        for i in range(1,len(ged_matrix)+1):
            #print(i)
            if(i in matched):
                dest_dict[i]=[-1,sys.maxsize]
                continue
            
            current_node=0
            current_min=sys.maxsize
            for j in range(0,len(ged_matrix[i])):
                if(ged_matrix[i][j]<current_min):
                    current_min=ged_matrix[i][j]
                    current_node=j+1
            if(current_min!=sys.maxsize):
                #print("new possibile min")
                dest_dict[i]=[current_node,current_min]
            else:
                dest_dict[i]=[-1,sys.maxsize]
        return 0



    cpdef double child_ged(self,nodeGData,nodeHData):
        #calcolo la ged sui figli, sommo i pesi delle substituion+pes dei nodi che non vengono matchati(eliminati)
        sum=0
        ged_matrix={} #ged_matrix[x1]=[cost_y1,cost_y2,....,cost_yn]
        for i in range(1,len(nodeGData[0])):
            _weightI=nodeGData[1][i]["weight"]
            ged_matrix[i]=[]
            for j in range(1,len(nodeHData[0])):
                _weightJ=nodeHData[1][j]["weight"]
                diff=abs(_weightI-_weightJ)
                ged_matrix[i].append(diff)
        
        matchedG=[]
        matchedH=[]
        for i in range(1,len(nodeGData[0])):
            dest_dict={}
            current_min_dict=[-2,-2,-2]

            self.gen_min_dict(ged_matrix,dest_dict,matchedG)
            #print(dest_dict)

            
            res=self.get_min_from_dict(dest_dict,current_min_dict)
            #print(current_min_dict)
            
            
            if(current_min_dict[0]==-1):
                #print("finiti i nodi matchabuli")
                break
            
            matchedG.append(current_min_dict[0])
            matchedH.append(current_min_dict[2])
            sum+=current_min_dict[1]
            res=self.delete_matched_node(ged_matrix,current_min_dict)
        

        #now sum all the ones that now should be remove/add from G
        for i in range(1,len(nodeGData[0])):
                if(not i in matchedG):
                    sum+=nodeGData[1][i]["weight"]
        

        
        return sum
        #now sum all the ones that now should be remove/add from H
        for j in range(1,len(nodeHData[0])):
                if(not j in matchedH):
                    sum+=nodeHData[1][j]["weight"]

        return sum

        


    cpdef double _old_child_ged(self,nodeGData,nodeHData):
       #calcolo la ged sui figli, sommo i pesi delle substituion+pes dei nodi che non vengono matchati(eliminati)     
           
        cur_min=sys.maxsize
        cur_node=[]
        sumI=0
        matched={}
        matchedG={}

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
                #matched[cur_node[0]]=cur_node[1]
                matched[cur_node[0]]=abs(_weightI-cur_node[1])
                matchedG[nodeGData[0][i]]=nodeGData[1][i]["weight"]
                cur_node=[]

        sum=0
        for node in matched:    
            #print(matched[node])
            sum+=matched[node]
        

        
        #now sum all the ones that now should be remove/add from G
        for i in range(1,len(nodeGData[0])):
                if(matchedG.has_key(nodeGData[0][i])):
                    continue
                else:
                    sum+=nodeGData[1][i]["weight"]

        
        #now sum all the ones that now should be remove/add from H
        for j in range(1,len(nodeHData[0])):
                if(matched.has_key(nodeHData[0][j])):
                    continue
                else:
                    sum+=nodeHData[1][j]["weight"]
        
        return sum
                


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
        
        nodeHData=list(H.nodes(data=True))
        _weightG=self.get_weight(node1,nodeGData)
        _weightH=self.get_weight(node2,nodeHData)

        #_weightG= nodeGData[1][0]["weight"]
        #_weightH= nodeHData[1][0]["weight"]

        #print("richiesto: " +  str(node1) + "il primo e' " + str(nodeGData[0][0]))

        #both root
        if(node1==nodeGData[0][0] and node2==nodeHData[0][0]):
            return abs(_weightG-_weightH)+self.child_ged(nodeGData,nodeHData)
        
        #both not root
        if(node1!=nodeGData[0][0] and node2!=nodeHData[0][0]):
            return abs(_weightG-_weightH)
        
        #node1 is a root but node2
        if(node1==nodeGData[0][0] and node2!=nodeHData[0][0]):
            return abs(_weightG-_weightH)+self.sum_child(nodeGData)+self.sum_nodes(nodeHData)-_weightH
        
        #node2 is a root but node1
        if(node1!=nodeGData[0][0] and node2==nodeHData[0][0]):
            return abs(_weightG-_weightH)+self.sum_child(nodeHData)+self.sum_nodes(nodeGData)-_weightG
        


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
        
        nodeGData=list(G.nodes(data=True))
        #print(nodeGData)
        _weight= nodeGData[1][i]["weight"]

        if i == j:
            penalty=0
            if(nodeGData[0][i]==nodeGData[0][0]): #vuoi eliminare il padre
                penalty=_weight*100
                return sys.maxsize

            return penalty+_weight+self.node_del+(G.degree(nodesG[i],weight=True)*self.edge_del) # Deleting a node implicate to delete in and out edges
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
