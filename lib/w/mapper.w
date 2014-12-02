\documentclass[11pt,oneside]{article}	%use"amsart"insteadof"article"forAMSLaTeXformat
\usepackage{geometry}		%Seegeometry.pdftolearnthelayoutoptions.Therearelots.
\geometry{letterpaper}		%...ora4paperora5paperor...
%\geometry{landscape}		%Activateforforrotatedpagegeometry
%\usepackage[parfill]{parskip}		%Activatetobeginparagraphswithanemptylineratherthananindent
\usepackage{graphicx}				%Usepdf,png,jpg,orepsßwithpdflatex;useepsinDVImode
								%TeXwillautomaticallyconverteps-->pdfinpdflatex		
\usepackage{amssymb}
\usepackage[colorlinks]{hyperref}

%----macros begin---------------------------------------------------------------
\usepackage{color}
\usepackage{amsthm}

\def\conv{\mbox{\textrm{conv}\,}}
\def\aff{\mbox{\textrm{aff}\,}}
\def\E{\mathbb{E}}
\def\R{\mathbb{R}}
\def\Z{\mathbb{Z}}
\def\tex{\TeX}
\def\latex{\LaTeX}
\def\v#1{{\bf #1}}
\def\p#1{{\bf #1}}
\def\T#1{{\bf #1}}

\def\vet#1{{\left(\begin{array}{cccccccccccccccccccc}#1\end{array}\right)}}
\def\mat#1{{\left(\begin{array}{cccccccccccccccccccc}#1\end{array}\right)}}

\def\lin{\mbox{\rm lin}\,}
\def\aff{\mbox{\rm aff}\,}
\def\pos{\mbox{\rm pos}\,}
\def\cone{\mbox{\rm cone}\,}
\def\conv{\mbox{\rm conv}\,}
\newcommand{\homog}[0]{\mbox{\rm homog}\,}
\newcommand{\relint}[0]{\mbox{\rm relint}\,}

%----macros end-----------------------------------------------------------------

\title{Domain mapping with LAR
\footnote{This document is part of the \emph{Linear Algebraic Representation with CoChains} (LAR-CC) framework~\cite{cclar-proj:2013:00}. \today}
}
\author{Alberto Paoluzzi}
%\date{}							%Activatetodisplayagivendateornodate

\begin{document}
\maketitle
\nonstopmode

\begin{abstract}
In this module a first implementation (no optimisations) is done of several \texttt{LAR} operators, reproducing the behaviour of the plasm  \texttt{STRUCT} and \texttt{MAP} primitives, but with better handling of the topology, including the stitching of decomposed (simplicial domains) about their possible sewing. A definition of specialised classes \texttt{Model}, \texttt{Mat} and \texttt{Verts} is also contained in this module, together with the design and the implementation of the \emph{traversal} algorithms for networks of structures.
\end{abstract}

\tableofcontents

%===============================================================================
\section{Introduction}
%===============================================================================

The \texttt{mapper} module, introduced here, aims to provide the tools needed to apply both dimension-independent affine transformations and general simplicial maps to geometric objects and assemblies developed within the LAR scheme. 

For this purpose, a simplicial decomposition of the $[0,1]^d$ hypercube ($d \geq 1$) with any possible \texttt{shape} is firstly given, followed by its scaled version with any  according $\texttt{size}\in\E^d$, being its position vector the mapped image of the point $\mathbf{1}\in\E^d$. A general mapping mechanism is specified, to map any domain decomposition (either simplicial or not) with a given set of coordinate functions, providing a piecewise-linear approximation of any curved embedding of a $d$-dimensional domain in any $\E^n$ space, with $n \geq d$. 
A suitable function is also given to identify corresponding vertices when mapping a domain decomposition of the fundamental polygon (or polyhedron) of a closed manifold. 

The geometric tools given in this chapter employ a normalised homogeneous representation of vertices of the represented shapes, where the added coordinate is the \emph{last} of the ordered list of vertex coordinates. The homogeneous representation of vertices is used \emph{implicitly}, by inserting the extra coordinate only when needed by the operation at hand, mainly for computing the product of the object's vertices times the matrix of an affine tensor. 

A set of primitive surface and solid shapes is also provided, via the mapping mechanism of a simplicial decomposition of a $d$-dimensional chart. A simplified version of the PLaSM specification of dimension-independent elementary affine transformation is given as well.

The second part of this module is dedicated to the development of a complete framework for the implementation of hierarchical assemblies of shapes and scene graphs, by using the simplest possible set of computing tools. In this case no hierarchical graphs or multigraph are employed, i.e.~no specialised data structures are produced. The ordered list model of hierarchical structures, inherited from PHIGS and PLaSM, is employed in this context. A recursive traversal is used to transform all the component parts of a hierarchical assembly into the reference frame of the first object of the assembly, i.e.~in world coordinates.

%===============================================================================
\section{Piecewise-linear mapping of topological spaces}
%===============================================================================

A very simple but foundational software subsystem is developed in this section, by giving a general mechanism to produce curved maps of topological spaces, via the simplicial decomposition of a chart, i.e.~of a planar embedding of the fundamental polygon of a $d$-dimensional manifold, and the definition of coordinate functions to be applied to its vertices ($0$-cells of the decomposition) to generate an embedding of the manifold.

\subsection{Domain decomposition}
%-------------------------------------------------------------------------------

A simplicial map is a map between simplicial complexes with the property that the images of the vertices of a simplex always span a simplex.  Simplicial maps are thus determined by their effects on vertices, and provide a piecewise-linear approximation of their underlying polyhedra. 

Since double simmeries are always present in the curved primitives generated in the module, an alternative cellular decomposition with cuboidal cells is provided.  The default choice is "cuboid".


\paragraph{Standard and scaled decomposition of unit domain}
The \texttt{larDomain} of given \texttt{shape} is decomposed by \texttt{larSimplexGrid1} as an hypercube of dimension $d \equiv\texttt{len(shape)}$, where the \texttt{shape} tuple provides the number or row, columns, pages, etc.~of the decomposition.

%-------------------------------------------------------------------------------
@D Generate a simplicial decomposition ot the $[0,1]^d$ domain
@{""" cellular decomposition of the unit d-cube """
def larDomain(shape, cell='cuboid'):
	if cell=='simplex': V,CV = larSimplexGrid1(shape)
	elif cell=='cuboid': V,CV = larCuboids(shape)
	V = larScale( [1./d for d in shape])(V)
	return [V,CV]
@}
%-------------------------------------------------------------------------------

A scaled simplicial decomposition is provided by the second-order  \texttt{larIntervals} function, with \texttt{len(shape)} and \texttt{len(size)} parameters, where the $d$-dimensionale vector \texttt{len(size)} is assumed as the scaling vector to be applied to the point $\mathbf{1}\in\E^d$.

%-------------------------------------------------------------------------------
@D Scaled simplicial decomposition ot the $[0,1]^d$ domain
@{def larIntervals(shape, cell='cuboid'):
	def larIntervals0(size):
		V,CV = larDomain(shape,cell)
		V = larScale( size)(V)
		return [V,CV]
	return larIntervals0
@}
%-------------------------------------------------------------------------------

\subsection{Mapping domain vertices}
The second-order texttt{larMap} function is the LAR implementation of the PLaSM primitive \texttt{MAP}.
It is applied to the array \texttt{coordFuncs} of coordinate functions and to the simplicially decomposed  \texttt{domain}, returning an embedded and/or curved \texttt{domain} instance.

%-------------------------------------------------------------------------------
@D Primitive mapping function 
@{def larMap(coordFuncs):
	if isinstance(coordFuncs, list): coordFuncs = CONS(coordFuncs)
	def larMap0(domain,dim=2):
		V,CV = domain
		V = AA(coordFuncs)(V)  # plasm CONStruction
		return [V,CV]
		# checkModel([V,CV])  TODO
	return larMap0
@}
%-------------------------------------------------------------------------------

\subsection{Identify close or coincident points}

The function \texttt{checkModel}, applied to a \texttt{model} parameter, i.e.~to a (vertices, cells)  pair, returns the model after identification of vertices with coincident or very close position vectors.
The \texttt{checkModel} function works as follows: first a dictionary \texttt{vertDict} is created, with key a suitably approximated position converted into a string by the \texttt{vcode} converter (given in the Appendix), and with value the list of vertex indices with the same (approximated) position. Then, an \texttt{invertedindex} array is created, associating each original vertex index with the new index produced by enumerating the (distinct) keys of the dictionary. Finally, a new list \texttt{CV} of cells is created, by substituting the new vertex indices for the old ones. 

%-------------------------------------------------------------------------------
@D Create a dictionary with key the point location
@{from collections import defaultdict
def checkModel(model,dim=2):
	V,CV = model; n = len(V)
	vertDict = defaultdict(list)
	for k,v in enumerate(V): vertDict[vcode(v)].append(k) 
	points,verts = TRANS(vertDict.items())
	invertedindex = [None]*n
	V = []
	for k,value in enumerate(verts):
		V.append(eval(points[k]))
		for i in value:
			invertedindex[i]=k	
	CV = [[invertedindex[v] for v in cell] for cell in CV]
	# filter out degenerate cells
	CV = [list(set(cell)) for cell in CV if len(set(cell))>=dim+1]
	return [V, CV]
@}
%-------------------------------------------------------------------------------


%-------------------------------------------------------------------------------
%===============================================================================
\section{Primitive objects}
\label{sec:generators}
%===============================================================================

A large number of primitive surfaces or solids is defined in this section, using the \texttt{larMap} mechanism and the coordinate functions of a suitable chart.

%-------------------------------------------------------------------------------
\subsection{1D primitives}
%-------------------------------------------------------------------------------

\paragraph{Circle}
%-------------------------------------------------------------------------------
@D Circle centered in the origin
@{def larCircle(radius=1.,angle=2*PI,dim=1):
	def larCircle0(shape=36):
		domain = larIntervals([shape])([angle])
		V,CV = domain
		x = lambda p : radius*COS(p[0])
		y = lambda p : radius*SIN(p[0])
		return larMap([x,y])(domain,dim)
	return larCircle0
@}
%-------------------------------------------------------------------------------
\paragraph{Helix curve}
%-------------------------------------------------------------------------------
@D Helix curve about the $z$ axis
@{def larHelix(radius=1.,pitch=1.,nturns=2,dim=1):
	def larHelix0(shape=36*nturns):
		angle = nturns*2*PI
		domain = larIntervals([shape])([angle])
		V,CV = domain
		x = lambda p : radius*COS(p[0])
		y = lambda p : radius*SIN(p[0])
		z = lambda p : (pitch/(2*PI)) * p[0]
		return larMap([x,y,z])(domain,dim)
	return larHelix0
@}
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
\subsection{2D primitives}
%-------------------------------------------------------------------------------
Some useful 2D primitive objects either in $\E^2$ or embedded in $\E^3$ are defined here, including 2D disks and rings, as well as cylindrical, spherical and toroidal surfaces.

\paragraph{Disk surface}
%-------------------------------------------------------------------------------
@D Disk centered in the origin
@{def larDisk(radius=1.,angle=2*PI):
	def larDisk0(shape=[36,1]):
		domain = larIntervals(shape)([angle,radius])
		V,CV = domain
		x = lambda p : p[1]*COS(p[0])
		y = lambda p : p[1]*SIN(p[0])
		return larMap([x,y])(domain)
	return larDisk0
@}
%-------------------------------------------------------------------------------
\paragraph{Helicoid surface}
%-------------------------------------------------------------------------------
@D Helicoid about the $z$ axis
@{def larHelicoid(R=1.,r=0.5,pitch=1.,nturns=2,dim=1):
	def larHelicoid0(shape=[36*nturns,2]):
		angle = nturns*2*PI
		domain = larIntervals(shape,'simplex')([angle,R-r])
		V,CV = domain
		V = larTranslate([0,r,0])(V)
		domain = V,CV
		x = lambda p : p[1]*COS(p[0])
		y = lambda p : p[1]*SIN(p[0])
		z = lambda p : (pitch/(2*PI)) * p[0]
		return larMap([x,y,z])(domain,dim)
	return larHelicoid0
@}
%-------------------------------------------------------------------------------

\paragraph{Ring surface}
%-------------------------------------------------------------------------------
@D Ring centered in the origin
@{def larRing(r1,r2,angle=2*PI):
	def larRing0(shape=[36,1]):
		V,CV = larIntervals(shape)([angle,r2-r1])
		V = larTranslate([0,r1])(V)
		domain = V,CV
		x = lambda p : p[1] * COS(p[0])
		y = lambda p : p[1] * SIN(p[0])
		return larMap([x,y])(domain)
	return larRing0
@}
%-------------------------------------------------------------------------------
\paragraph{Cylinder surface}
%-------------------------------------------------------------------------------
@D Cylinder surface with $z$ axis
@{from scipy.linalg import det
"""
def makeOriented(model):
	V,CV = model
	out = []
	for cell in CV: 
		mat = scipy.array([V[v]+[1] for v in cell]+[[0,0,0,1]])
		if det(mat) < 0.0:
			out.append(cell)
		else:
			out.append([cell[1]]+[cell[0]]+cell[2:])
	return V,out
"""
def larCylinder(radius,height,angle=2*PI):
	def larCylinder0(shape=[36,1]):
		domain = larIntervals(shape)([angle,1])
		V,CV = domain
		x = lambda p : radius*COS(p[0])
		y = lambda p : radius*SIN(p[0])
		z = lambda p : height*p[1]
		mapping = [x,y,z]
		model = larMap(mapping)(domain)
		# model = makeOriented(model)
		return model
	return larCylinder0
@}
%-------------------------------------------------------------------------------
\paragraph{Spherical surface of given radius}
%-------------------------------------------------------------------------------
@D Spherical surface of given radius
@{def larSphere(radius=1,angle1=PI,angle2=2*PI):
	def larSphere0(shape=[18,36]):
		V,CV = larIntervals(shape,'simplex')([angle1,angle2])
		V = larTranslate([-angle1/2,-angle2/2])(V)
		domain = V,CV
		x = lambda p : radius*COS(p[0])*COS(p[1])
		y = lambda p : radius*COS(p[0])*SIN(p[1])
		z = lambda p : radius*SIN(p[0])
		return larMap([x,y,z])(domain)
	return larSphere0
@}
%-------------------------------------------------------------------------------
\paragraph{Toroidal surface}
%-------------------------------------------------------------------------------
@D Toroidal surface of given radiuses
@{def larToroidal(r,R,angle1=2*PI,angle2=2*PI):
	def larToroidal0(shape=[24,36]):
		domain = larIntervals(shape,'simplex')([angle1,angle2])
		V,CV = domain
		x = lambda p : (R + r*COS(p[0])) * COS(p[1])
		y = lambda p : (R + r*COS(p[0])) * SIN(p[1])
		z = lambda p : -r * SIN(p[0])
		return larMap([x,y,z])(domain)
	return larToroidal0
@}
%-------------------------------------------------------------------------------
\paragraph{Crown surface}
%-------------------------------------------------------------------------------
@D Half-toroidal surface of given radiuses
@{def larCrown(r,R,angle=2*PI):
	def larCrown0(shape=[24,36]):
		V,CV = larIntervals(shape,'simplex')([PI,angle])
		V = larTranslate([-PI/2,0])(V)
		domain = V,CV
		x = lambda p : (R + r*COS(p[0])) * COS(p[1])
		y = lambda p : (R + r*COS(p[0])) * SIN(p[1])
		z = lambda p : -r * SIN(p[0])
		return larMap([x,y,z])(domain)
	return larCrown0
@}
%-------------------------------------------------------------------------------

%-------------------------------------------------------------------------------
\subsection{3D primitives}
%-------------------------------------------------------------------------------


\paragraph{Solid Box}
%-------------------------------------------------------------------------------
@D Solid box of given extreme vectors
@{def larBox(minVect,maxVect):
	size = DIFF([maxVect,minVect])
	print "size =",size
	box = larApply(s(*size))(larCuboids([1,1,1]))
	print "box =",box
	return larApply(t(*minVect))(box)
@}
%-------------------------------------------------------------------------------

\paragraph{Solid helicoid}
%-------------------------------------------------------------------------------
@D Solid helicoid about the $z$ axis
@{def larSolidHelicoid(thickness=.1,R=1.,r=0.5,pitch=1.,nturns=2.,steps=36):
	def larSolidHelicoid0(shape=[steps*int(nturns),1,1]):
		angle = nturns*2*PI
		domain = larIntervals(shape)([angle,R-r,thickness])
		V,CV = domain
		V = larTranslate([0,r,0])(V)
		domain = V,CV
		x = lambda p : p[1]*COS(p[0])
		y = lambda p : p[1]*SIN(p[0])
		z = lambda p : (pitch/(2*PI))*p[0] + p[2]
		return larMap([x,y,z])(domain)
	return larSolidHelicoid0
@}
%-------------------------------------------------------------------------------


\paragraph{Solid Ball}
%-------------------------------------------------------------------------------
@D Solid Sphere of given radius
@{def larBall(radius=1,angle1=PI,angle2=2*PI):
	def larBall0(shape=[18,36]):
		V,CV = checkModel(larSphere(radius,angle1,angle2)(shape))
		return V,[range(len(V))]
	return larBall0
@}
%-------------------------------------------------------------------------------

\paragraph{Solid cylinder}
%-------------------------------------------------------------------------------
@D Solid cylinder of given radius and height
@{def larRod(radius,height,angle=2*PI):
	def larRod0(shape=[36,1]):
		V,CV = checkModel(larCylinder(radius,height,angle)(shape))
		return V,[range(len(V))]
	return larRod0
@}
%-------------------------------------------------------------------------------

\paragraph{Hollow cylinder}
%-------------------------------------------------------------------------------
@D Hollow cylinder of given radiuses and height
@{def larHollowCyl(r,R,height,angle=2*PI):
	def larHollowCyl0(shape=[36,1,1]):
		V,CV = larIntervals(shape)([angle,R-r,height])
		V = larTranslate([0,r,0])(V)
		domain = V,CV
		x = lambda p : p[1] * COS(p[0])
		y = lambda p : p[1] * SIN(p[0])
		z = lambda p : p[2] * height
		return larMap([x,y,z])(domain)
	return larHollowCyl0
@}
%-------------------------------------------------------------------------------

\paragraph{Hollow sphere}
%-------------------------------------------------------------------------------
@D Hollow sphere of given radiuses
@{def larHollowSphere(r,R,angle1=PI,angle2=2*PI):
	def larHollowSphere0(shape=[36,1,1]):
		V,CV = larIntervals(shape)([angle1,angle2,R-r])
		V = larTranslate([-angle1/2,-angle2/2,r])(V)
		domain = V,CV
		x = lambda p : p[2]*COS(p[0])*COS(p[1])
		y = lambda p : p[2]*COS(p[0])*SIN(p[1])
		z = lambda p : p[2]*SIN(p[0])
		return larMap([x,y,z])(domain)
	return larHollowSphere0
@}
%-------------------------------------------------------------------------------


\paragraph{Solid torus}
%-------------------------------------------------------------------------------
@D Solid torus of given radiuses
@{def larTorus(r,R,angle1=2*PI,angle2=2*PI):
	def larTorus0(shape=[24,36,1]):
		domain = larIntervals(shape)([angle1,angle2,r])
		V,CV = domain
		x = lambda p : (R + p[2]*COS(p[0])) * COS(p[1])
		y = lambda p : (R + p[2]*COS(p[0])) * SIN(p[1])
		z = lambda p : -p[2] * SIN(p[0])
		return larMap([x,y,z])(domain)
	return larTorus0
@}
%-------------------------------------------------------------------------------

\paragraph{Solid pizza}
%-------------------------------------------------------------------------------
@D Solid pizza of given radiuses
@{def larPizza(r,R,angle=2*PI):
	assert angle <= PI
	def larPizza0(shape=[24,36]):
		V,CV = checkModel(larCrown(r,R,angle)(shape))
		V += [[0,0,-r],[0,0,r]]
		return V,[range(len(V))]
	return larPizza0
@}
%-------------------------------------------------------------------------------

%===============================================================================
\section{Computational framework}
%===============================================================================
\subsection{Exporting the library}
%-------------------------------------------------------------------------------
@O lib/py/mapper.py
@{""" Mapping functions and primitive objects """
@< Initial import of modules @>
from larstruct import *
@< Affine transformations of $d$-points @>
@< Generate a simplicial decomposition ot the $[0,1]^d$ domain @>
@< Scaled simplicial decomposition ot the $[0,1]^d$ domain @>
@< Create a dictionary with key the point location @>
@< Primitive mapping function @>
@< Basic tests of mapper module @>
@< Circle centered in the origin @>
@< Helix curve about the $z$ axis @>
@< Disk centered in the origin @>
@< Helicoid about the $z$ axis @>
@< Ring centered in the origin @>
@< Spherical surface of given radius @>
@< Cylinder surface with $z$ axis @>
@< Toroidal surface of given radiuses @>
@< Half-toroidal surface of given radiuses @>
@< Solid box of given extreme vectors @>
@< Solid Sphere of given radius @>
@< Solid helicoid about the $z$ axis @>
@< Solid cylinder of given radius and height @>
@< Solid torus of given radiuses @>
@< Solid pizza of given radiuses @>
@< Hollow cylinder of given radiuses and height @>
@< Hollow sphere of given radiuses @>
@< Symbolic utility to represent points as strings @>
@< Remove the unused vertices from a LAR model pair @>
@}
%-------------------------------------------------------------------------------
%===============================================================================
\subsection{Examples}
%===============================================================================

\paragraph{3D rotation about a general axis}
The approach used by \texttt{lar-cc} to specify a general 3D rotation is shown in the following example,
by passing the rotation function \texttt{r} the components \texttt{a,b,c} of the unit vector \texttt{axis} scaled by the rotation \texttt{angle}. 

%-------------------------------------------------------------------------------
@O test/py/mapper/test02.py
@{""" General 3D rotation of a toroidal surface """
@< Initial import of modules @>
from mapper import *
model = checkModel(larToroidal([0.2,1])())
angle = PI/2; axis = UNITVECT([1,1,0])
a,b,c = SCALARVECTPROD([ angle, axis ])
model = larApply(r(a,b,c))(model)
VIEW(STRUCT(MKPOLS(model)))
@}
%-------------------------------------------------------------------------------


\paragraph{3D elementary rotation of a 2D circle}
A simpler specification is needed when the 3D rotation is about a coordinate axis. In this case the rotation angle can be directly given as the unique non-zero parameter of the the rotation function \texttt{r}. The rotation axis (in this case the $x$ one) is specified by the non-zero (angle) position.

%-------------------------------------------------------------------------------
@O test/py/mapper/test03.py
@{""" Elementary 3D rotation of a 2D circle """
@< Initial import of modules @>
from mapper import *
model = checkModel(larCircle(1)())
model = larEmbed(1)(model)
model = larApply(r(PI/2,0,0))(model)
VIEW(STRUCT(MKPOLS(model)))
@}
%-------------------------------------------------------------------------------




%===============================================================================
\subsection{Tests about domain}
%===============================================================================

\paragraph{Mapping domains}
The generations of mapping domains of different dimension (1D, 2D, 3D) is shown below.
	
%-------------------------------------------------------------------------------
@D Basic tests of mapper module
@{@< Initial import of modules @>
from larstruct import *
if __name__=="__main__":
	V,EV = larDomain([5])
	VIEW(EXPLODE(1.5,1.5,1.5)(MKPOLS((V,EV))))
	V,EV = larIntervals([24])([2*PI])
	VIEW(EXPLODE(1.5,1.5,1.5)(MKPOLS((V,EV))))
		
	V,FV = larDomain([5,3])
	VIEW(EXPLODE(1.5,1.5,1.5)(MKPOLS((V,FV))))
	V,FV = larIntervals([36,3])([2*PI,1.])
	VIEW(EXPLODE(1.5,1.5,1.5)(MKPOLS((V,FV))))
		
	V,CV = larDomain([5,3,1])
	VIEW(EXPLODE(1.5,1.5,1.5)(MKPOLS((V,CV))))
	V,CV = larIntervals([36,2,3])([2*PI,1.,1.])
	VIEW(EXPLODE(1.5,1.5,1.5)(MKPOLS((V,CV))))
@}
%-------------------------------------------------------------------------------

\paragraph{Testing some primitive object generators}
The various model generators given in Section~\ref{sec:generators} are tested here, including LAR 2D circle, disk, and ring, as well as the 3D cylinder, sphere, and toroidal surfaces, and the solid objects ball, rod, crown, pizza, and torus.

%-------------------------------------------------------------------------------
@O test/py/mapper/test01.py
@{""" Circumference of unit radius """
@< Initial import of modules @>
from mapper import *
model = larCircle(1)()
VIEW(EXPLODE(1.2,1.2,1.2)(MKPOLS(model)))
model = larHelix(1,0.5,4)()
VIEW(EXPLODE(1.2,1.2,1.2)(MKPOLS(model)))
model = larDisk(1)([36,4])
VIEW(EXPLODE(1.2,1.2,1.2)(MKPOLS(model)))
model = larHelicoid(1,0.5,0.1,10)()
VIEW(EXPLODE(1.2,1.2,1.2)(MKPOLS(model)))
model = larRing(.9, 1.)([36,2])
VIEW(EXPLODE(1.2,1.2,1.2)(MKPOLS(model)))
model = larCylinder(.5,2.)([32,1])
VIEW(STRUCT(MKPOLS(model)))
model = larSphere(1,PI/6,PI/4)([6,12])
VIEW(STRUCT(MKPOLS(model)))
model = larBall(1)()
VIEW(EXPLODE(1.2,1.2,1.2)(MKPOLS(model)))
model = larSolidHelicoid(0.2,1,0.5,0.5,10)()
VIEW(STRUCT(MKPOLS(model)))
model = larRod(.25,2.)([32,1])
VIEW(STRUCT(MKPOLS(model)))
model = larToroidal(0.5,2)()
VIEW(STRUCT(MKPOLS(model)))
model = larCrown(0.125,1)([8,48])
VIEW(STRUCT(MKPOLS(model)))
model = larPizza(0.05,1,PI/3)([8,48])
VIEW(STRUCT(MKPOLS(model)))
model = larTorus(0.5,1)()
VIEW(STRUCT(MKPOLS(model)))
model = larBox([-1,-1,-1],[1,1,1])
VIEW(STRUCT(MKPOLS(model)))
model = larHollowCyl(0.8,1,1,angle=PI/4)([12,2,2])
VIEW(STRUCT(MKPOLS(model)))
model = larHollowSphere(0.8,1,PI/6,PI/4)([6,12,2])
VIEW(STRUCT(MKPOLS(model)))
@}
%-------------------------------------------------------------------------------


\subsection{Volumetric utilities}


\paragraph{Limits of a LAR Model}
%-------------------------------------------------------------------------------
@D Model limits
@{def larLimits (model):
	if isinstance(model,tuple): 
		V,CV = model
		verts = scipy.asarray(V)
	else: verts = model.verts
	return scipy.amin(verts,axis=0).tolist(), scipy.amax(verts,axis=0).tolist()
	
assert larLimits(larSphere()()) == ([-1.0, -1.0, -1.0], [1.0, 1.0, 1.0])
@}
%-------------------------------------------------------------------------------

\paragraph{Alignment}
%-------------------------------------------------------------------------------
@D Alignment primitive
@{def larAlign (args):
	def larAlign0 (args,pols):
		pol1, pol2 = pols
		box1, box2 = (larLimits(pol1), larLimits(pol2))
		print "box1, box2 =",(box1, box2)
		
	return larAlign0
@}
%-------------------------------------------------------------------------------

%===============================================================================
\appendix
\section{Utility functions}
%===============================================================================



def FLATTEN( pol )
	temp = Plasm.shrink(pol,True)
	hpcList = []
	for I in range(len(temp.childs)):			
		g,vmat, hmat = temp.childs[I].g,temp.childs[I].vmat, temp.childs[I].hmat
		g.embed(vmat. dim)
		g.transform(vmat, hmat)
		hpcList += [Hpc(g)]
	return hpcList
	
VIEW(STRUCT( FLATTEN(pol) ))


%-------------------------------------------------------------------------------
@D Initial import of modules
@{from pyplasm import *
from scipy import *
import os,sys

""" import modules from larcc/lib """
sys.path.insert(0, 'lib/py/')
import lar2psm
from simplexn import *
from larcc import *
from largrid import *
from lar2psm import *
from larstruct import *
@< MaKe a list of HPC objects from a LAR model @>
@< Explode the scene using \texttt{sx,sy,sz} scaling parameters @>
@}
%-------------------------------------------------------------------------------

%------------------------------------------------------------------
@d MaKe a list of HPC objects from a LAR model
@{def MKPOLS (model):
    V,FV = model
    pols = [MKPOL([[V[v] for v in f],[range(1,len(f)+1)], None]) for f in FV]
    return pols  
@| MKPOLS @}
%------------------------------------------------------------------

%------------------------------------------------------------------
@d Explode the scene using \texttt{sx,sy,sz} scaling parameters
@{def EXPLODE (sx,sy,sz):
    def explode0 (scene):
        centers = [CCOMB(S1(UKPOL(obj))) for obj in scene]
        scalings = len(centers) * [S([1,2,3])([sx,sy,sz])]
        scaledCenters = [UK(APPLY(pair)) for pair in
                         zip(scalings, [MK(p) for p in centers])]
        translVectors = [ VECTDIFF((p,q)) for (p,q) in zip(scaledCenters, centers) ]
        translations = [ T([1,2,3])(v) for v in translVectors ]
        return STRUCT([ t(obj) for (t,obj) in zip(translations,scene) ])
    return explode0  
@| EXPLODE @}
%------------------------------------------------------------------

\paragraph{Affine transformations of points} Some primitive maps of points to points are given in the following, including translation, rotation and scaling of array of points via direct transformation of their coordinates. Second-order functions are used in order to employ their curried version to transform geometric assemblies.

%------------------------------------------------------------------
@D Affine transformations of $d$-points
@{def larTranslate (tvect):
	def larTranslate0 (points):
		return [VECTSUM([p,tvect]) for p in points]
	return larTranslate0

def larRotate (angle):		# 2-dimensional !! TODO: n-dim
	def larRotate0 (points):
		a = angle
		return [[x*COS(a)-y*SIN(a), x*SIN(a)+y*COS(a)] for x,y in points]
	return larRotate0

def larScale (svect):
	def larScale0 (points):
		print "\n points =",points
		print "\n svect =",svect
		return [AA(PROD)(TRANS([p,svect])) for p in points]
	return larScale0
@}
%------------------------------------------------------------------



\subsection{Numeric utilities}

A small set of utilityy functions is used to transform a point representation as array of coordinates into a string of fixed format to be used as point key into python dictionaries.

%------------------------------------------------------------------
@D Symbolic utility to represent points as strings
@{""" TODO: use package Decimal (http://docs.python.org/2/library/decimal.html) """
PRECISION = 4 

def prepKey (args): return "["+", ".join(args)+"]"

def fixedPrec(value):
	out = round(value*10**PRECISION)/10**PRECISION
	if out == -0.0: out = 0.0
	return str(out)
	
def vcode (vect): 
	"""
	To generate a string representation of a number array.
	Used to generate the vertex keys in PointSet dictionary, and other similar operations.
	"""
	return prepKey(AA(fixedPrec)(vect))
@}
%------------------------------------------------------------------


\bibliographystyle{amsalpha}
\bibliography{mapper}

\end{document}