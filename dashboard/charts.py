from __future__ import annotations

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
from matplotlib.figure import Figure
from matplotlib.ticker import FuncFormatter


def _prepare_plot() -> None:
    sns.set_theme(style="whitegrid", context="notebook")


def revenue_trend(monthly: pd.DataFrame) -> Figure:
    _prepare_plot()
    frame = monthly.copy()
    frame["revenue_month"] = pd.to_datetime(frame["revenue_month"])
    figure, axis = plt.subplots(figsize=(12, 5))
    sns.lineplot(
        data=frame,
        x="revenue_month",
        y="merchandise_revenue_brl",
        marker="o",
        linewidth=2.5,
        color="#176b87",
        ax=axis,
    )
    axis.set(
        title="Delivered merchandise sales by purchase month",
        xlabel="Purchase month",
        ylabel="Sales (BRL, freight excluded)",
    )
    axis.yaxis.set_major_formatter(
        FuncFormatter(lambda value, _: f"R$ {value / 1000:,.0f}k")
    )
    figure.autofmt_xdate()
    figure.tight_layout()
    return figure


def category_revenue(categories: pd.DataFrame) -> Figure:
    _prepare_plot()
    frame = categories.sort_values("delivered_revenue_brl")
    figure, axis = plt.subplots(figsize=(10, 6))
    sns.barplot(
        data=frame,
        x="delivered_revenue_brl",
        y="category",
        color="#176b87",
        ax=axis,
    )
    axis.set(
        title="Top product categories by delivered sales",
        xlabel="Delivered merchandise sales (BRL)",
        ylabel="Category",
    )
    axis.xaxis.set_major_formatter(
        FuncFormatter(lambda value, _: f"R$ {value / 1000:,.0f}k")
    )
    figure.tight_layout()
    return figure


def customer_segments(segments: pd.DataFrame) -> Figure:
    _prepare_plot()
    frame = segments.sort_values("customers")
    figure, axis = plt.subplots(figsize=(10, 5))
    sns.barplot(
        data=frame,
        x="customers",
        y="rfm_segment",
        color="#3a9d8f",
        ax=axis,
    )
    axis.set(
        title="Customer count by delivered-order RFM segment",
        xlabel="Customers",
        ylabel="RFM segment",
    )
    axis.xaxis.set_major_formatter(
        FuncFormatter(lambda value, _: f"{value:,.0f}")
    )
    figure.tight_layout()
    return figure


def cohort_retention(cohorts: pd.DataFrame) -> Figure:
    _prepare_plot()
    frame = cohorts.copy()
    frame["cohort_month"] = pd.to_datetime(frame["cohort_month"]).dt.strftime(
        "%Y-%m"
    )
    matrix = frame.pivot(
        index="cohort_month",
        columns="months_since_first_purchase",
        values="retention_pct",
    )
    figure, axis = plt.subplots(
        figsize=(max(10, matrix.shape[1] * 0.55), max(7, matrix.shape[0] * 0.34))
    )
    sns.heatmap(
        matrix,
        cmap="crest",
        vmin=0,
        vmax=100,
        annot=True,
        fmt=".0f",
        linewidths=0.25,
        cbar_kws={"label": "Customers returning (%)"},
        ax=axis,
    )
    axis.set(
        title="Delivered-customer cohort retention",
        xlabel="Months since first delivered purchase",
        ylabel="Cohort month",
    )
    figure.tight_layout()
    return figure


def delivery_by_state(states: pd.DataFrame) -> Figure:
    _prepare_plot()
    frame = states.copy()
    frame["state_label"] = frame.apply(
        lambda row: f"{row['customer_state']} (n={row['delivered_orders']:,})",
        axis=1,
    )
    frame = frame.sort_values("average_delivery_hours")
    figure, axis = plt.subplots(figsize=(11, 6))
    sns.barplot(
        data=frame,
        x="average_delivery_hours",
        y="state_label",
        color="#e08e45",
        ax=axis,
    )
    axis.set(
        title="Longest average delivery times by destination state",
        xlabel="Average delivery time (hours)",
        ylabel="State (eligible deliveries)",
    )
    figure.tight_layout()
    return figure


def top_products(products: pd.DataFrame) -> Figure:
    _prepare_plot()
    frame = products.sort_values("delivered_revenue_brl").copy()
    frame["product_label"] = frame["product_id"].str.slice(0, 8)
    figure, axis = plt.subplots(figsize=(10, 6))
    sns.barplot(
        data=frame,
        x="delivered_revenue_brl",
        y="product_label",
        color="#8c6bb1",
        ax=axis,
    )
    axis.set(
        title="Top products by delivered merchandise sales",
        xlabel="Delivered merchandise sales (BRL)",
        ylabel="Product ID prefix",
    )
    axis.xaxis.set_major_formatter(
        FuncFormatter(lambda value, _: f"R$ {value / 1000:,.0f}k")
    )
    figure.tight_layout()
    return figure


def top_sellers(sellers: pd.DataFrame) -> Figure:
    _prepare_plot()
    frame = sellers.sort_values("delivered_revenue_brl").copy()
    frame["seller_label"] = frame["seller_id"].str.slice(0, 8)
    figure, axis = plt.subplots(figsize=(10, 7))
    sns.barplot(
        data=frame,
        x="delivered_revenue_brl",
        y="seller_label",
        color="#6a994e",
        ax=axis,
    )
    axis.set(
        title="Top sellers by delivered merchandise sales",
        xlabel="Delivered merchandise sales (BRL)",
        ylabel="Seller ID prefix",
    )
    axis.xaxis.set_major_formatter(
        FuncFormatter(lambda value, _: f"R$ {value / 1000:,.0f}k")
    )
    figure.tight_layout()
    return figure
