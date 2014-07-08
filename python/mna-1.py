#!/usr/bin/python

import gzip, time, sys
from optparse import OptionParser
from collections import defaultdict
from os import listdir
from os.path import isfile, join

class MultidimGraphStatsHolder():
   def __init__(self):
      self.nodes = defaultdict(NodeStatsHolder)
      self.edges = 0
      self.dimensions = defaultdict(DimensionStatsHolder)
      self.dim_edge_parent = defaultdict(lambda : defaultdict(int))
      self.dim_node_parent = defaultdict(lambda : defaultdict(int))

class NodeStatsHolder():
   def __init__(self):
      self.neighbors = 0
      self.degree = 0
      self.dim_degree = defaultdict(int)
      self.dim_degree_xor = defaultdict(int)
      self.dr_weighted = defaultdict(float)

class DimensionStatsHolder():
   def __init__(self):
      self.degree = 0
      self.degree_uniq = 0
      self.nodes = 0

def node_stats(network_file, extended):
   sys.stdout.write("Analyzing the network %s...\n" % network_file)
   start_time = time.time()
   if extended:
      src_index = 1
      trg_index = 2
      dim_index = 3
   else:
      src_index = 0
      trg_index = 1
      dim_index = 2
   g = MultidimGraphStatsHolder()
   previous_src = -1
   previous_trg = -1
   dimensions_per_edge = set()
   f = open(network_file, 'r')
   for line in f:
      fields = line.strip().split()
      g.edges += 1
      src = int(fields[src_index])
      trg = int(fields[trg_index])
      dim = int(fields[dim_index])
      if not src in g.nodes:
         g.nodes[src] = NodeStatsHolder()
      if not trg in g.nodes:
         g.nodes[trg] = NodeStatsHolder()
      if not dim in g.nodes:
         g.dimensions[dim] = DimensionStatsHolder()
      g.nodes[src].degree += 1
      g.nodes[trg].degree += 1
      g.nodes[src].dim_degree[dim] += 1
      g.nodes[trg].dim_degree[dim] += 1
      if previous_src == -1 or (src == previous_src and trg == previous_trg):
         if previous_src == -1:
            g.nodes[src].neighbors += 1
            g.nodes[trg].neighbors += 1 
         dimensions_per_edge.add(dim)
      else:
         dimSize = len(dimensions_per_edge)
         avg_dim = 1.0 / dimSize
         for dimension in dimensions_per_edge:
            g.nodes[previous_src].dr_weighted[dimension] += avg_dim
            g.nodes[previous_trg].dr_weighted[dimension] += avg_dim
            g.dimensions[dimension].degree += 1
            for d2 in dimensions_per_edge:
               g.dim_edge_parent[dimension][d2] += 1
         if dimSize == 1:
            the_dim = next(iter(dimensions_per_edge))
            g.nodes[previous_src].dim_degree_xor[the_dim] += 1
            g.nodes[previous_trg].dim_degree_xor[the_dim] += 1
            g.dimensions[the_dim].degree_uniq += 1
         g.nodes[src].neighbors += 1
         g.nodes[trg].neighbors += 1
         dimensions_per_edge = set()
         dimensions_per_edge.add(dim) 
      previous_src = src
      previous_trg = trg
   f.close()
   sys.stdout.write("Analysis executed in %ds\n" % (time.time() - start_time))
   return g

def node_stats_to_file(network_file, number_of_dimensions, g):
   sys.stdout.write("Printing node statistics...\n")
   f = gzip.open("%s_node_stats.gz" % network_file, 'wb')
   f.write("ID Neighbors")
   for i in range(number_of_dimensions):
      f.write(" %sDRXOR %sDR %sDRAVG" % (i, i, i))
   f.write('\n')
   for i in g.nodes:
      f.write("%d %d" % (i, g.nodes[i].neighbors))
      for j in range(number_of_dimensions):
         dr_xor = float(g.nodes[i].dim_degree_xor[j]) / g.nodes[i].neighbors
         dr = float(g.nodes[i].dim_degree[j]) / g.nodes[i].neighbors
         dr_avg = float(g.nodes[i].dr_weighted[j]) / g.nodes[i].neighbors
         f.write(" %s %s %s" % (dr_xor, dr, dr_avg))
      f.write('\n')
   f.close()

def dim_stats_to_file(network_file, number_of_dimensions, g):
   sys.stdout.write("Printing dimension statistics...\n")
   f = open("%s_dimensions_stats" % network_file, 'w')
   f.write("Degrees\nLevel DimensionDegree DimensionDegreeUniqueness\n")
   for i in range(number_of_dimensions):
      if g.dimensions[i].degree > 0:
         f.write("%d %s %s\n" % (i, float(g.dimensions[i].degree) / g.edges, float(g.dimensions[i].degree_uniq) / g.dimensions[i].degree))
      else:
         f.write("%d 0.0 NaN\n" % i)
   f.write("Node Jaccard\nLevel1 Level2 Value\n")
   for i in g.nodes:
      for j in range(number_of_dimensions):
         if g.nodes[i].dim_degree[j] > 0:
            g.dimensions[j].nodes += 1
            for y in range(number_of_dimensions):
               if g.nodes[i].dim_degree[y] > 0:
                  g.dim_node_parent[j][y] += 1
   for i in range(number_of_dimensions - 1):
      for j in range(i + 1, number_of_dimensions):
         f.write("%d %d %s\n" % (i, j, (2.0 * g.dim_node_parent[i][j]) / float(g.dimensions[i].nodes + g.dimensions[j].nodes)))
   f.write("Edge Jaccard\nLevel1 Level2 Value\n")
   for i in range(number_of_dimensions - 1):
      for j in range(i + 1, number_of_dimensions):
         f.write("%d %d %s\n" % (i, j, (2.0 * g.dim_edge_parent[i][j]) / float(g.dimensions[i].degree + g.dimensions[j].degree)))
   f.close()

usage = "usage: python %prog [options] filename"
parser = OptionParser(usage)
parser.add_option("-f", "--file", dest="file", help="Single input file in gspan format")
parser.add_option("-d", "--directory", dest="directory", help="Input files are enclosed in the given directory in GSpan format")
parser.add_option("-D", "--dimensions", dest="dimensions", type="int", help="Number of dimensions")
parser.add_option("-e", "--extended", dest="extended", action="store_true", default = False, help="Use extended input, that gives ^e")
parser.add_option("-n", "--node_stats", dest="node_stats", action="store_true", default = False, help="Print the nodes_stats.gz")
parser.add_option("-i", "--dim_stats", dest="dim_stats", action="store_true", default = False, help="Print the dimension_stats")
(options, args) = parser.parse_args()

number_of_dimensions = options.dimensions
network_file = options.file
print_node_stats = options.node_stats
print_dim_stats = options.dim_stats
extended = options.extended
directory = options.directory

if network_file != None:
   g = node_stats(network_file, extended)
   if print_node_stats:
      node_stats_to_file(network_file, number_of_dimensions, g)
   if print_dim_stats:
      dim_stats_to_file(network_file, number_of_dimensions, g)
elif directory != None:
   network_files = set([f for f in listdir(directory) if isfile(join(directory, f))])
   for network_file in network_files:
      g = node_stats(join(directory, network_file), extended)
      if print_node_stats:
         node_stats_to_file(join(directory, network_file), number_of_dimensions, g)
      if print_dim_stats:
         dim_stats_to_file(join(directory, network_file), number_of_dimensions, g)
