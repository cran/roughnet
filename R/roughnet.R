#' Create a rough network
#' @description plot a network using rough.js
#' @param g igraph object
#' @param roughness numeric vector for roughness of vertices and edges
#' @param bowing numeric vector for bowing of vertices and edges
#' @param font font size and font family for labels
#' @param width width
#' @param height height
#' @param elementId DOM id
#' @param chunk_name markdown specific
#' @return htmlwidget containing the drawn network
#' @details the function recognizes the following attributes
#' Vertex attributes (e.g. V(g)$shape):
#'
#' * \emph{shape} one of "circle", "rectangle", "heart", "air", "earth", "fire", "water"
#' * \emph{fill} vertex fill color
#' * \emph{color} vertex stroke color
#' * \emph{stroke} stroke size
#' * \emph{fillstyle} one of "hachure", "solid", "zigzag", "cross-hatch", "dots", "sunburst", "dashed", "zigzag-line"
#' * \emph{size} vertex size
#' * \emph{label} vertex label
#' * \emph{pos} position of vertex label (c)enter, (n)orth, (e)ast, (s)outh, (w)est
#'
#' Edge attributes (e.g. E(g)$color):
#'
#' * \emph{color} edge color
#' * \emph{width} edge width
#'
#' Default values are used if one of the attributes is not found.
#'
#' The result of a roughnet call can be printed to file with `save_roughnet()`
#'
#' More details on roughjs can be found on https://github.com/rough-stuff/rough/wiki
#'
#' @examples
#' library(igraph)
#'
#' g <- make_graph("Zachary")
#' V(g)$shape <- "circle"
#' V(g)$shape[c(1, 34)] <- "rectangle"
#' V(g)$fill <- c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3")[membership(cluster_louvain(g))]
#' V(g)$fillstyle <- c("hachure", "zigzag", "cross-hatch", "dots")[membership(cluster_louvain(g))]
#' V(g)$color <- "black"
#' V(g)$size <- 30
#' V(g)$stroke <- 2
#' E(g)$color <- "#AEAEAE"
#' roughnet(g, width = 960, height = 600)
#'
#' @export
roughnet <- function(g, roughness = c(1, 1), bowing = c(1, 1), font = "30px Arial",
                     width = NULL, height = NULL, elementId = NULL, chunk_name = "canvas") {

  # prepare styles ----
  # vertices
  if (!"shape" %in% igraph::vertex_attr_names(g)) {
    igraph::V(g)$shape <- "circle"
  }
  if (!"fill" %in% igraph::vertex_attr_names(g)) {
    vfill <- "black"
  } else {
    vfill <- igraph::V(g)$fill
  }
  if (!"color" %in% igraph::vertex_attr_names(g)) {
    vcol <- "black"
  } else {
    vcol <- igraph::V(g)$color
  }

  if (!"size" %in% igraph::vertex_attr_names(g)) {
    vsize <- 30
  } else {
    vsize <- igraph::V(g)$size
  }

  if (!"stroke" %in% igraph::vertex_attr_names(g)) {
    vstroke <- 1
  } else {
    vstroke <- igraph::V(g)$stroke
  }

  if (!"fillstyle" %in% igraph::vertex_attr_names(g)) {
    vfillstyle <- "hachure"
  } else {
    vfillstyle <- igraph::V(g)$fillstyle
  }

  if (!"label" %in% igraph::vertex_attr_names(g)) {
    vlabel <- ""
  } else {
    vlabel <- igraph::V(g)$label
  }
  if (!"pos" %in% igraph::vertex_attr_names(g)) {
    vpos <- "c"
  } else {
    vpos <- igraph::V(g)$pos
  }

  # edges
  if (!"color" %in% igraph::edge_attr_names(g)) {
    ecols <- "black"
  } else {
    ecols <- igraph::E(g)$color
  }

  if (!"width" %in% igraph::edge_attr_names(g)) {
    ewidth <- 2
  } else {
    ewidth <- igraph::E(g)$width
  }


  # layout ----
  if (!all(c("x", "y") %in% igraph::vertex_attr_names(g))) {
    xy <- graphlayouts::layout_with_stress(g)
  } else {
    xy <- cbind(igraph::V(g)$x, igraph::V(g)$y)
  }

  if (is.null(width)) {
    xy[, 1] <- normalise(xy[, 1], to = c(100, 700))
  } else {
    xy[, 1] <- normalise(xy[, 1], to = c(width * 0.1, width * 0.9))
  }
  if (is.null(height)) {
    xy[, 2] <- normalise(xy[, 2], to = c(100, 500))
  } else {
    xy[, 2] <- normalise(xy[, 2], to = c(height * 0.1, height * 0.9))
  }



  nodes <- data.frame(
    x = xy[, 1],
    y = xy[, 2],
    xend = 0,
    yend = 0,
    shape = igraph::V(g)$shape,
    color = vcol,
    fill = vfill,
    fillstyle = vfillstyle,
    width = vstroke,
    size = vsize,
    label = vlabel,
    pos = vpos
  )

  nodes$xf <- nodes$x
  nodes$yf <- nodes$y

  nodes$x <- ifelse(nodes$shape != "circle", nodes$x - nodes$size / 2, nodes$x)
  nodes$y <- ifelse(nodes$shape != "circle", nodes$y - nodes$size / 2, nodes$y)

  nodes$roughness <- roughness[1]
  nodes$bowing <- bowing[1]

  nodes1 <- nodes
  nodes2 <- nodes
  nodes1$fill <- "white"
  nodes1$fillstyle <- "solid"

  el <- igraph::get.edgelist(g, names = FALSE)
  edges <- data.frame(
    x = xy[el[, 1], 1],
    y = xy[el[, 1], 2],
    xend = xy[el[, 2], 1],
    yend = xy[el[, 2], 2],
    shape = "edge",
    color = ecols,
    fill = "black",
    fillstyle = "solid",
    width = ewidth,
    size = 1,
    label = "",
    pos = "c",
    xf = 0,
    yf = 0
  )

  edges$roughness <- roughness[2]
  edges$bowing <- bowing[2]

  if (!all(vlabel == "")) {
    nodes3 <- nodes2
    nodes3$shape <- "text"
    data <- rbind(edges, nodes1, nodes2, nodes3)
  } else {
    data <- rbind(edges, nodes1, nodes2)
  }



  x <- list(
    data = jsonlite::toJSON(data),
    font = font,
    id = chunk_name
  )

  # create widget
  htmlwidgets::createWidget(
    name = "roughnet",
    x = x,
    width = width,
    height = height,
    package = "roughnet",
    elementId = elementId
  )
}

normalise <- function(x, from = range(x), to = c(0, 1)) {
  x <- (x - from[1]) / (from[2] - from[1])
  if (!identical(to, c(0, 1))) {
    x <- x * (to[2] - to[1]) + to[1]
  }
  x
}
