""" boundary operators """
from larlib import *
""" convex-cells boundary operator --- best implementation """
def boundary(cells,facets):
    lenV = max(max(CAT(cells)),max(CAT(facets)))+1
    csrCV = csrCreate(cells,lenV)
    csrFV = csrCreate(facets,lenV)
    csrFC = csrFV * csrCV.T
    facetLengths = [csrFacet.getnnz() for csrFacet in csrFV]
    m,n = csrFC.shape
    facetCoboundary = [[csrFC.indices[csrFC.indptr[h]+k] 
        for k,v in enumerate(csrFC.data[csrFC.indptr[h]:csrFC.indptr[h+1]]) 
            if v==facetLengths[h]] for h in range(m)]
    indptr = [0]+list(cumsum(AA(len)(facetCoboundary)))
    indices = CAT(facetCoboundary)
    data = [1]*len(indices)
    return csr_matrix((data,indices,indptr),shape=(m,n),dtype='b')

""" path-connected-cells boundary operator """
def larUnsignedBoundary2(CV,FV,EV):
    out = boundary(CV,FV)
    def csrRowSum(h): 
        return sum(out.data[out.indptr[h]:out.indptr[h+1]])    
    unreliable = [h for h in range(len(FV)) if csrRowSum(h) > 2]
    if unreliable != []:
        csrBBMat = boundary(FV,EV) * boundary(CV,FV)
        lenV = max(max(CAT(CV)),max(CAT(FV)),max(CAT(EV)))+1
        FE = larcc.crossRelation0(lenV,FV,EV)
        out = csrBoundaryFilter2(unreliable,out,csrBBMat,CV,FE)
    return out

def boundary3(CV,FV,EV):
    out = larUnsignedBoundary2(CV,FV,EV)
    lenV = max(max(CAT(CV)),max(CAT(FV)),max(CAT(EV)))+1
    VV = AA(LIST)(range(lenV))
    csrBBMat = scipy.sparse.csc_matrix(boundary(FV,EV) * larUnsignedBoundary2(CV,FV,EV))
    def csrColCheck(h): 
        return any([val for val in csrBBMat.data[csrBBMat.indptr[h]:csrBBMat.indptr[h+1]] if val>2])    
    unreliable = [h for h in range(len(CV)) if csrColCheck(h)]
    if unreliable != []:
        FE = larcc.crossRelation0(lenV,FV,EV)
        out = csrBoundaryFilter3(unreliable,out,csrBBMat,CV,FE)
    return out
""" path-connected-cells boundary operator """
import larlib
import larcc
from larcc import *

def csrBoundaryFilter2(unreliable,out,csrBBMat,cells,FE):
    for row in unreliable:
        for j in range(len(cells)):
            if out[row,j] == 1:
                cooCE = csrBBMat.T[j].tocoo()
                flawedCells = [cooCE.col[k] for k,datum in enumerate(cooCE.data)
                    if datum>2]
                if all([facet in flawedCells  for facet in FE[row]]):
                    out[row,j]=0
    return out

def csrBoundaryFilter3(unreliable,out,csrBBMat,cells,FE):
    for col in unreliable:
        cooCE = csrBBMat.T[col].tocoo()
        flawedCells = [cooCE.col[k] for k,datum in enumerate(cooCE.data)
                    if datum>2]
        for j in range(out.shape[0]):
            if out[j,col] == 1:
                if all([facet in flawedCells  for facet in FE[j]]):
                    out[j,col]=0
    return out

def totalChain(cells):
    return csr_matrix(len(cells)*[[1]])

def boundaryCells(cells,facets):
    csrBoundaryMat = boundary(cells,facets)
    csrChain = csr_matrix(totalChain(cells))
    csrBoundaryChain = csrBoundaryMat * csrChain
    out = [k for k,val in enumerate(csrBoundaryChain.data.tolist()) if val == 1]
    return out

def boundary2Cells(cells,facets,faces):
    csrBoundaryMat = larUnsignedBoundary2(cells,facets,faces)
    csrChain = csr_matrix(totalChain(cells))
    csrBoundaryChain = csrBoundaryMat * csrChain
    out = [k for k,val in enumerate(csrBoundaryChain.data.tolist()) if val == 1]
    return out

def boundary3Cells(cells,facets,faces):
    csrBoundaryMat = boundary3(cells,facets,faces)
    csrChain = csr_matrix(totalChain(cells))
    csrBoundaryChain = csrBoundaryMat * csrChain
    out = [k for k,val in enumerate(csrBoundaryChain.data.tolist()) if val == 1]
    return out

""" Marshalling a structure to a LAR cellular model """
import boolean,inters

def struct2Marshal(struct):
    W,FW,EW = struct2lar(struct)
    quadArray = [[W[v] for v in face] for face in FW]
    parts = boolean.boxBuckets3d(boolean.containmentBoxes(quadArray))
    Z,FZ,EZ = boolean.spacePartition(W,FW,EW, parts)
    V,FV,EV = inters.larSimplify((Z,FZ,EZ),radius=0.0001)
    return V,FV,EV

""" Compute the signed 2-boundary matrix """
import triangulation
    
def larSignedBoundary2(V,FV,EV):
    efOp = larFaces2Edges(V,FV,EV)
    FE = [efOp([k]) for k in range(len(FV))]
    data,row,col = [],[],[]
    for f in range(len(FE)):
        cycle_data = triangulation.find_cycles(V,[EV[e] for e in FE[f]])
        vcycles = cycle_data['v_cycles']
        ecycles = cycle_data['e_cycles']
        pairs = zip(vcycles,ecycles)
        vertEdgeCycles = [zip(vcycle,[FE[f][e] for e in ecycle]) for vcycle,ecycle in pairs]
        vertEdgeCycles = sorted(vertEdgeCycles,key=len)[:-1]
        coefficients = [1 if v == EV[e][0] else -1 for cycle in vertEdgeCycles for (v,e) in cycle]
        ecycle = [e for cycle in vertEdgeCycles for (v,e) in cycle]
        data += coefficients
        row += ecycle
        col += [f]*len(ecycle)
        #print f,len(data),len(row),len(col)
    signedBoundary2 = coo_matrix((data,(row,col)), shape=(len(EV),len(FV)),dtype='b')
    return csr_matrix(signedBoundary2)

""" Boundary of a 3-complex """
import larcc
"""  WHY wrong ????  TOCHECK !!
def larUnsignedBoundary3(V,CV,FV,EV):
    VV = AA(LIST)(range(len(V)))
    operator3 = larcc.chain2BoundaryChain(boundary3(CV,FV,EV))
    operator2 = larcc.chain2BoundaryChain(larUnsignedBoundary2(FV,EV,VV))
    def larUnsignedBoundary30(chain):
        BF = operator3(chain)
        faceCoords = len(FV)*[0]
        for f in BF: faceCoords[f] = 1
        BE = operator2(faceCoords)
        return V,[FV[f] for f in BF],[EV[e] for e in BE]
    return larUnsignedBoundary30
"""
def larUnsignedBoundary3(V,CV,FV,EV):
    VV = AA(LIST)(range(len(V)))
    operator3 = larcc.chain2BoundaryChain(boundary3(CV,FV,EV))
    operator2 = larcc.chain2BoundaryChain(larUnsignedBoundary2(FV,EV,VV))
    def larUnsignedBoundary30(chain):
        BF = operator3(chain)
        BE = set()
        for f in BF: 
            faceCoords = len(FV)*[0]
            faceCoords[f] = 1
            BE = BE.union(operator2(faceCoords))
        return V,[FV[f] for f in BF],[EV[e] for e in BE]
    return larUnsignedBoundary30

""" Query from 3-chain to incident 2-chain """
def larCells2Faces(CV,FV,EV):
    csrFC = boundary3(CV,FV,EV)
    def larCells2Faces0(chain):
        chainCoords = csc_matrix((csrFC.shape[1],1),dtype='b')
        for k in chain: chainCoords[k,0] = 1
        out = csrFC * chainCoords
        return out.tocoo().row.tolist()
    return larCells2Faces0

""" Query from 3-chain to incident 1-chain """
def larCells2Edges(CV,FV,EV):
    lenV = max(CAT(CV))+1
    VV = AA(LIST)(range(lenV))
    csrEC = larUnsignedBoundary2(FV,EV,VV) * boundary3(CV,FV,EV)
    def larCells2Faces0(chain):
        chainCoords = csc_matrix((csrEC.shape[1],1),dtype='b')
        for k in chain: chainCoords[k,0] = 1
        out = csrEC * chainCoords
        return out.tocoo().row.tolist()
    return larCells2Faces0

""" Query from 2-chain to incident 1-chain """
def larFaces2Edges(V,FV,EV):
    VV = AA(LIST)(range(len(V)))
    csrEF = larUnsignedBoundary2(FV,EV,VV)
    def larCells2Faces0(chain):
        chainCoords = csc_matrix((csrEF.shape[1],1),dtype='b')
        for k in chain: chainCoords[k,0] = 1
        out = csrEF * chainCoords
        return out.tocoo().row.tolist()
    return larCells2Faces0

""" kfaces-to-kfaces relations """

def larCells2Cells(CV,FV,EV):
    csrMat = boundary3(CV,FV,EV)
    csrCC = csrMat.T * csrMat
    def larCells2Cells0(chain):
        chainCoords = csc_matrix((csrCC.shape[1],1),dtype='b')
        for k in chain: chainCoords[k,0] = 1
        out = csrCC * chainCoords
        return out.tocoo().row.tolist()
    return larCells2Cells0

def larFaces2Faces(FV,EV):
    lenV = max(CAT(FV)) + 1
    VV = AA(LIST)(range(lenV))
    csrMat = larUnsignedBoundary2(FV,EV,VV)
    csrFF = csrMat.T * csrMat
    def larFaces2Faces0(chain):
        chainCoords = csc_matrix((csrFF.shape[1],1),dtype='b')
        for k in chain: chainCoords[k,0] = 1
        out = csrFF * chainCoords
        return out.tocoo().row.tolist()
    return larFaces2Faces0

def larEdges2Edges(EV,VV):
    lenV = len(VV)
    csrMat = boundary(EV,VV)
    csrEE = csrMat.T * csrMat
    def larFaces2Faces0(chain):
        chainCoords = csc_matrix((csrEE.shape[1],1),dtype='b')
        for k in chain: chainCoords[k,0] = 1
        out = csrEE * chainCoords
        return out.tocoo().row.tolist()
    return larFaces2Faces0

""" Transformation from chain coordinates to explicit chain data """
def coords2chain(chainCoords):
    coo = coo_matrix(chainCoords)
    return [(e,val) for e,val in zip(coo.row,coo.data)]

""" Choose the next face on ordered coboundary of edge """
def adjFace(boundaryOperator,EV,EF_angle,faceChainOrientation):
    def adjFace0(edge,orientation):
        if orientation > 0:  edgeLoop = REVERSE(EF_angle[edge])
        elif orientation < 0:  edgeLoop = EF_angle[edge]
        edgeLoop = edgeLoop + [edgeLoop[0]]  # all positive indices
        print "edgeLoop =",edgeLoop
        
        print "faceChainOrientation =",faceChainOrientation
        pivotFace = set([f for f,_ in faceChainOrientation]).intersection(edgeLoop).pop()
        if pivotFace in edgeLoop:
            pivotIndex = edgeLoop.index(pivotFace)
        else:
            pivotIndex = edgeLoop.index(-pivotFace)
        adjacentFace = edgeLoop[pivotIndex+1]
        
        theSign = boundaryOperator[edge,adjacentFace]
        print "adjacentFace,edge,pivotFace,theSign =",adjacentFace,edge,pivotFace,theSign
        return adjacentFace, -(theSign*orientation)
        #return adjacentFace, theSign
    return adjFace0

""" Choose the start facet in extracting the facet representation of a cell """
def chooseStartFace(FV,faceCounter):
    print "\n>>>>>>> ECCOMI"
    for f in range(len(FV)):
        if faceCounter[f,0]==1 and faceCounter[f,1]==0: return (f,-1)
        elif faceCounter[f,0]==0 and faceCounter[f,1]==1: return (f,1)
    if sum(array(faceCounter))==2*len(FV): return (-1,999)
    else: return (0,1)

""" Extract the signed representation of a basis element """
def signedBasis(boundaryOperator):
   facesByEdges = csc_matrix(boundaryOperator)
   m,n = facesByEdges.shape
   edges,signs = [],[]
   for i in range(n):
      edges += [facesByEdges.indices[facesByEdges.indptr[i]:facesByEdges.indptr[i+1]].tolist()]
      signs += [facesByEdges.data[facesByEdges.indptr[i]:facesByEdges.indptr[i+1]].tolist()]
   return zip(edges,signs)

""" Return the signed boundary matrix of a 3-complex """
def larSignedBoundary3((V,FV,EV)):
   """
   sort on angles the co-boundaries of 1-cells (loops of signed faces)
   """
   model = V,FV,EV
   faceCounter = zeros((len(FV),2),dtype='b')
   CF = []
   efOp = larFaces2Edges(V,FV,EV)
   FE = [efOp([k]) for k in range(len(FV))]
   EF_angle, _,_,_ = faceSlopeOrdering(model,FE)
   """
   initialize the 2-coboundary array of arrays, with boundary 2-faces of 3-cells by row
   """
   m = len(FV)
   nonWorkedFaces = set(range(m))
   coboundary_2 = []
   boundaryOperator = larSignedBoundary2(V,FV,EV)
   FEbasis = signedBasis(boundaryOperator)
   cellNumber=0
   row,col,data = [],[],[]
   """
   repeat until the set of non-worked faces is empty
   """
   while True:
      print "\n>>>>>>> CIAO"
      """
      Take an elementary 2-chain F = [f]
      """
      #startFace = nonWorkedFaces.pop()
      startFace,orientation = chooseStartFace(FV,faceCounter)
      print "\n\n*** startFace =",startFace
      if startFace == -1: break
      nonWorkedFaces = nonWorkedFaces.difference({startFace})
      faceChainOrientation = {(startFace,orientation)}
      """
      compute the oriented 1-boundary  E := partial_2(F) (loops of signed edges)
      """
      vect = csc_matrix((m,1),dtype='b')
      for face,orientation in faceChainOrientation:  
          vect[face] = orientation
      edgeCycleCoords = boundaryOperator * vect
      edgeCycle = coords2chain(edgeCycleCoords)
      print "\nedgeCycle esterno=",edgeCycle
      """
      repeat until E[F] = \emptyset
      """
      while edgeCycle != []:
         """
         for each edge on E 
         """
         look4face = adjFace(boundaryOperator,EV,EF_angle,faceChainOrientation)
         for edge,orientation in edgeCycle:
            print "\nedge,orientation=",edge,orientation
            adjacentFace,orientation = look4face(edge,orientation)
            """
            assemble all the g_i with F in a new 2-chain F := F \cup [g_i]
            """
            faceChainOrientation = faceChainOrientation.union(
                [(adjacentFace,orientation)])
            print "faceChainOrientation=",faceChainOrientation
            #VIEW(STRUCT(MKTRIANGLES((V,[FV[f] for f in faceChain],EV),color=True)))
            nonWorkedFaces = nonWorkedFaces.difference([adjacentFace])
            print "nonWorkedFaces=",nonWorkedFaces
            """
            """
         vect = csc_matrix((m,1),dtype='b')
         for face,orientation in faceChainOrientation:  
             vect[face] = orientation
         edgeCycleCoords = boundaryOperator * vect
         print "\nedgeCycle interno pre=",edgeCycle
         edgeCycle = coords2chain(edgeCycleCoords)
         print "\nedgeCycle interno post=",edgeCycle
      """
      put the signed F elements in a new column of $\partial_3$ (new row of coboundary_2)
      """
      row += [face for face,_ in faceChainOrientation]
      col += [cellNumber for face,orientation in faceChainOrientation]
      data += [orientation for _,orientation in faceChainOrientation]
      cellNumber += 1
      
      for face,orientation in faceChainOrientation:
          if orientation == 1: faceCounter[face,0]+=1
          elif orientation == -1: faceCounter[face,1]+=1
      print "faceChainOrientation =",faceChainOrientation   
      print "faceCounter =",faceCounter   
          
      CF += [[face for face,_ in faceChainOrientation]]
      print "CF =",CF

   outMatrix = coo_matrix((data, (row,col)), shape=(m,cellNumber),dtype='b')
   return csr_matrix(outMatrix),CF,faceCounter

""" Test the signed boundary matrix of a 3-complex """
if __name__=="__main__":

   V,[VV,EV,FV,CV] = larCuboids([2,1,1],True)
   cubeGrid = Struct([(V,FV,EV)],"cubeGrid")
   cubeGrids = Struct(2*[cubeGrid,t(.5,.5,.5),r(0,0,PI/6)])

   V,FV,EV = struct2Marshal(cubeGrids)
   csrmat,CF,faceCounter = larSignedBoundary3((V,FV,EV))
   csrmat.todense()

