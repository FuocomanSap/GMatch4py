import numpy as np
cimport numpy as np
from .abstract_graph_edit_dist cimport AbstractGraphEditDistance


cdef class GraphEditDistance(AbstractGraphEditDistance):
    cpdef object relabel_cost(self, node1, node2, G, H)
    cpdef double substitute_cost(self, node1, node2, G, H)
    cdef double delete_cost(self, int i, int j, nodesG, G)
    cdef double insert_cost(self, int i, int j, nodesH, H)
    cpdef double child_ged(self,nodeGData,nodeHData)
    cpdef double sum_child(self,nodeGData)
    cpdef double sum_nodes(self,nodeGData)
    cpdef double get_weight(self,node,nodeGData)
    cpdef double delete_matched_node(self,ged_matrix,current_min_dict)
    cpdef double get_min_from_dict(self,dest_dict,current_min_dict)
    cpdef double gen_min_dict(self,ged_matrix,dest_dict,matched)
    cpdef double _old_child_ged(self,nodeGData,nodeHData)