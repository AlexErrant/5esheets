#!/usr/bin/env python3

from sqla_graphs import ModelGrapher

from dnd5esheets.models import BaseModel

grapher = ModelGrapher(
    show_operations=True, style={"node_table_header": {"bgcolor": "#000088"}}
)
graph = grapher.graph(BaseModel.__subclasses__())
graph.write_png("model_graph.png")
