# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.3.1
#   kernelspec:
#     display_name: Python 3
#     language: python
#     name: python3
# ---

# %%
import pandas as pd
import networkx as nx
import janitor
from sklearn.cluster import KMeans
import warnings
import cenpy
import geopandas as gpd
from sklearn.manifold import TSNE

warnings.simplefilter("ignore", np.ComplexWarning)

# %%
gdf = (
    gpd.read_file("../DataInput/geo/tl_2019_us_county/tl_2019_us_county.shp")
    .assign(fips=lambda x: x.STATEFP + x.COUNTYFP)[["fips", "geometry"]]
    .copy()
)

# %%
df = pd.read_stata("../DataOutput/01_prepare_data/inflow_masterfile.dta")
itr = pd.read_stata("../DataOutput/01_prepare_data/inflow_masterfile.dta", chunksize=1)
var_labels = itr.variable_labels()

# %%
df.head()


# %%
def get_vertices_and_edges(df, cutoff, year):
    candidates = df.query("year == @year and exempt >= @cutoff")[
        ["cty_base_fips", "cty_flow_fips"]
    ]
    assert not candidates.duplicated().any()

    vertices = set(list(df.cty_base_fips.unique()) + list(df.cty_flow_fips.unique()))
    return vertices, [tuple(t[1:]) for t in candidates.itertuples() if t[1] != t[2]]


# %%
def process_year_unweighted_edges(df, cutoff, year, K=2):
    vertices, edges = get_vertices_and_edges(df, cutoff, year)
    g = nx.Graph()
    g.add_nodes_from(vertices)
    g.add_edges_from(edges)

    # Take giant component
    giant_component = g.subgraph(max(nx.connected_components(g), key=len))
    adj_mat = nx.adjacency_matrix(giant_component)
    eigenvals, eigenvecs = np.linalg.eig(adj_mat.todense())

    first_K = np.array(eigenvecs[:, :K]).astype(float).copy()
    first_K = (
        first_K * np.sign(first_K[:, 0])[:, np.newaxis]
    )  # Making sure first eigenvector is positive

    kmeans = KMeans(n_clusters=K, max_iter=1000, n_init=50).fit(
        (first_K[:, 1:] / first_K[:, [0]])
    )
    boundary = kmeans.cluster_centers_.mean()
    label = ((first_K[:, 1:] / first_K[:, [0]]) > boundary).astype(int).flatten()

    return (
        giant_component,
        adj_mat,
        eigenvals,
        eigenvecs,
        first_K,
        kmeans,
        boundary,
        label,
    )


# %%
def process_year_with_weighted_edges(df, year, K=2):
    df_graph = (
        df.query("year == @year and nonmigr == 0")[
            ["cty_base_fips", "cty_flow_fips", "exempt"]
        ]
        .assign(
            minfips=lambda x: np.minimum(
                x.cty_base_fips.astype(int), x.cty_flow_fips.astype(int)
            )
            .astype(str)
            .str.zfill(5)
        )
        .assign(
            maxfips=lambda x: np.maximum(
                x.cty_base_fips.astype(int), x.cty_flow_fips.astype(int)
            )
            .astype(str)
            .str.zfill(5)
        )
        .groupby(["minfips", "maxfips"])["exempt"]
        .sum()
        .reset_index()
    )

    verts = set(list(df_graph["minfips"].unique()) + list(df_graph["maxfips"].unique()))
    g = nx.Graph()
    g.add_nodes_from(verts)
    g.add_weighted_edges_from(
        [tuple(x[1:]) for x in df_graph.query("exempt >= 1").itertuples()]
    )
    giant_component = g.subgraph(max(nx.connected_components(g), key=len))

    adj_mat = nx.adjacency_matrix(giant_component).todense()
    eigenvals, eigenvecs = np.linalg.eig(adj_mat)

    first_K = np.array(eigenvecs[:, :K]).astype(float)
    first_K = first_K * np.sign(
        first_K[:, [0]]
    )  # Making sure first eigenvector is positive

    cluster_mat = first_K[:, 1:] / first_K[:, [0]]

    kmeans = KMeans(n_clusters=K, max_iter=1000, n_init=50).fit(cluster_mat)
    return (giant_component, adj_mat, eigenvals, eigenvecs, first_K, kmeans)


# %%
def draw_map(nodes, labels, **kwargs):
    fig, ax = plt.subplots(1, figsize=(10, 5))
    (
        gdf[~gdf["fips"].str.startswith("02") & ~gdf["fips"].str.startswith("15")]
        .merge(pd.DataFrame({"fips": nodes, "label": labels}), how="inner")
        .plot(column="label", cmap="Set1", linewidth=0.1, ax=ax, **kwargs)
    )
    ax.set_aspect("auto")
    return ax


# %% [markdown]
# # Unweighted, undirected network
# $(u,v) \in E$ if $\text{flow}_{u\to v} > c$ or $\text{flow}_{v\to u} > c$. 

# %%
(
    giant_component,
    adj_mat,
    eigenvals,
    eigenvecs,
    first_K,
    kmeans,
    boundary,
    label,
) = process_year_unweighted_edges(df, 40, 2009, K=5)

# %%

# %%
# Variance explained?
first = 20
plt.bar(x=list(range(1, first+1)), height=np.abs(eigenvals[:first].flatten()))

# %%
sns.scatterplot(
    first_K[:, 1] / first_K[:, 0],
    first_K[:, 2] / first_K[:, 0],
    marker="o",
    hue=kmeans.labels_,
    palette="Set1",
)

# %%
# This is weird

# tsne = TSNE(perplexity=15)
# tsne_xy = tsne.fit_transform(first_K[:, 1] / first_K[:, [0]])
# sns.scatterplot(
#     tsne_xy[:, 0],
#     tsne_xy[:, 1],
#     marker="o",
#     hue=kmeans.labels_,
#     palette="Set1",
# )

# kmeans_tsne = KMeans(5)
# kmeans_tsne.fit(tsne_xy)

# sns.scatterplot(
#     tsne_xy[:, 0],
#     tsne_xy[:, 1],
#     marker="o",
#     hue=kmeans_tsne.labels_,
#     palette="Set1",
# )

# %%
draw_map(list(giant_component.nodes()), kmeans.labels_)

# %% [markdown]
# # Weighted directed network
# $w_{u,v} = \text{flow}_{u\to v} + \text{flow}_{v \to u}$. The adjacency matrix is now the collection of $w_{u,v}$'s. If we model $$
# w_{u,v} \sim \text{Poisson}(\theta_u \theta_v \lambda_{c(u),c(v)}),
# $$
# then the expectation of the adjacency matrix is $$
# E A_{u,v} = \theta_u \theta_v \lambda_{c(u),c(v)}.
# $$
# which has the same structure as the DCBM. So I conjecture that the same technique for the DCBM can be used in this setting

# %%
# Net migration

# %%
(
    giant_component,
    adj_mat,
    eigenvals,
    eigenvecs,
    first_K,
    kmeans,
) = process_year_with_weighted_edges(df, 2009, K=10)

# %%
first = 20
plt.bar(x=list(range(1, first+1)), height=np.abs(eigenvals[:first].flatten()))

# %%
sns.scatterplot(
    first_K[:, 1] / first_K[:, 0],
    first_K[:, 2] / first_K[:, 0],
    marker="o",
    hue=kmeans.labels_,
    palette="Set1",
)

# %%
draw_map(list(giant_component.nodes()), kmeans.labels_)

# %%
