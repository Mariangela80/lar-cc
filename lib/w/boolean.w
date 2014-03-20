\documentclass[11pt,oneside]{article}	%use"amsart"insteadof"article"forAMSLaTeXformat
\usepackage{geometry}		%Seegeometry.pdftolearnthelayoutoptions.Therearelots.
\geometry{letterpaper}		%...ora4paperora5paperor...
%\geometry{landscape}		%Activateforforrotatedpagegeometry
%\usepackage[parfill]{parskip}		%Activatetobeginparagraphswithanemptylineratherthananindent
\usepackage{graphicx}				%Usepdf,png,jpg,orepsßwithpdflatex;useepsinDVImode
								%TeXwillautomaticallyconverteps-->pdfinpdflatex		
\usepackage{amssymb}
\usepackage{hyperref}

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

\title{Boolean operations with chains
\footnote{This document is part of the \emph{Linear Algebraic Representation with CoChains} (LAR-CC) framework~\cite{cclar-proj:2013:00}. \today}
}
\author{Alberto Paoluzzi}
%\date{}							%Activatetodisplayagivendateornodate

\begin{document}
\maketitle
\nonstopmode

%-------------------------------------------------------------------------------
\begin{abstract}
Boolean operations are a major addition to every geometric package. Union, intersection, difference and complementation of decomposed spaces are discussed and implemented in this module by making use of the Linear Algebraic Representation (LAR) introduced in \cite{Dicarlo:2014:TNL:2543138.2543294}. First, the two finite decompositions are merged, by merging their vertices (0-cells of support spaces); then a Delaunay complex based on the vertex set union is computed, and the shared $d$-chain is extracted and splitted, according to the cell structure of the input $d$-chains. The Boolean results are finally computed by sum, product of difference of the coordinate representation of the (splitted) argument chains, by using the novel chain-basis resulted from the splitting phase.
\end{abstract}
\tableofcontents
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
\section{Introduction}

In this section we introduce and shortly outline our novel algorithm for Boolean operations with chain of cells from different space decompositions implemented in this LAR-CC module.

The input object are denoted in the remainder as $X_1$ and $X_2$, and their finite cell decompositions as $\Lambda_1$ and $\Lambda_2$. Our goal is to compute $X = X_1\, op\, X_2$, where $op\in \{ \cup, \cap, -, \ominus \}$ or $\complement X$, based on a common decomposition $\Lambda = \Lambda_1\, op\, \Lambda_2$, with $\Lambda$ being a suitably fragmented decomposition of the $X$ space. 

Of course, we aim to compute a minimal (in some sense) decomposition, making the best use of the LAR framework, based on CSR representation of sparse binary matrices and standard matrix algebra operations.
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
\section{Merging 0-cells}
%-------------------------------------------------------------------------------
\subsection{Lexicographic ordering of vertex coordinates}
%-------------------------------------------------------------------------------
\subsection{Translation of vertices}
%-------------------------------------------------------------------------------
\subsection{Translation of $d$-cells}
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
\section{Extracting pivot $d$-cells}
%-------------------------------------------------------------------------------
\subsection{Computation of Delaunay complex $\Sigma$}
%-------------------------------------------------------------------------------
\subsection{Partition of $\Sigma$ into $\Sigma_\Delta$ and $\Sigma_\Omega$}
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
\section{Splitting argument chains}
%-------------------------------------------------------------------------------
\subsection{Matching cells in $\Sigma_\Delta$ with spanning chains in $\Lambda_1,\Lambda_2$}
%-------------------------------------------------------------------------------
\subsection{Splitting cells}
%-------------------------------------------------------------------------------
\subsection{Keeping cell dictionaries updated }
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
\section{Boolean outputs computations}
%-------------------------------------------------------------------------------
%-------------------------------------------------------------------------------
\section{Tests}
%-------------------------------------------------------------------------------
\subsection{Generation of random data}
%-------------------------------------------------------------------------------
\subsection{Disk saving of test data}
%-------------------------------------------------------------------------------
\subsection{Algorithm execution}
%-------------------------------------------------------------------------------
\subsection{Unit tests}
%-------------------------------------------------------------------------------

\bibliographystyle{amsalpha}
\bibliography{boolean}

\end{document}
