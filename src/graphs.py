from pathlib import Path

import pandas as pd
import plotly.express as px
import requests

IMGUR_CLIENT_ID = "4975f1d3020260e"
IMGUR_CLIENT_SECRET = "61b59ff225592f86034a5cdbd4fc2fe03a6e1ad4"
URL = "https://api.imgur.com/3/upload"
HEADERS = {"Authorization": f"Client-ID {IMGUR_CLIENT_ID}"}


HEIGHT = 350
WIDTH = 910


def upload_image_imgur(image_path: Path) -> str:
    return ""
    with open(file=image_path, mode="rb") as image_file:
        response = requests.post(URL, headers=HEADERS, files={"image": image_file})

    if response.status_code == 200:
        image_url = response.json()["data"]["link"]
        print(f"Image uploaded to Imgur. URL: {image_url}")
    else:
        print("Failed to upload image to Imgur.")
        print(response.json())

    return image_url


def generate_graph(
    excel: Path,
    row_range: slice,
    title: str,
    output_filename: str,
) -> str:
    df = pd.read_excel(excel)
    df.columns = df.columns.str.replace("percent_", "")
    df = df.iloc[row_range]

    df_long = df.melt(id_vars=["split"], var_name="player", value_name="percent")

    fig = px.bar(
        df_long,
        x="split",
        y="percent",
        color="player",
        barmode="stack",
        title=None,
        labels={"split": "Split", "percent": "Percentage", "player": "Player"},
    )

    fig.update_layout(
        template="plotly_dark",
        legend_title="Player",
        title_text=title,
        title_x=0.5,
        xaxis_title=None,
        yaxis_title=None,
    )

    graph_path = (
        Path(r"H:\Juan\3. Projects\GH Sawken\Python\UpdateGoldsGlobal\graphs")
        / output_filename
    )
    fig.write_image(graph_path, height=HEIGHT, width=WIDTH)

    return upload_image_imgur(image_path=graph_path)


def graph_village(excel: Path) -> str:
    return generate_graph(
        excel=excel,
        row_range=slice(0, 26),  # Rows 0 to 25
        title="Percentage of resets per player per split (Village)",
        output_filename="Village resets.png",
    )


def graph_castle(excel: Path) -> str:
    return generate_graph(
        excel=excel,
        row_range=slice(26, 49),
        title="Percentage of resets per player per split (Castle)",
        output_filename="Castle resets.png",
    )


def graph_island(excel: Path) -> str:
    return generate_graph(
        excel=excel,
        row_range=slice(49, None),
        title="Percentage of resets per player per split (Island)",
        output_filename="Island resets.png",
    )
