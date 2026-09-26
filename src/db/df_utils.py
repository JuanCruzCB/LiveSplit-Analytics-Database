import polars as pl
from polars import DataFrame

from db.time_utils import compute_lowest_time, format_duration, parse_duration


def add_best_and_cumulative_best_cols(times: DataFrame) -> DataFrame:
    """
    Receives a DataFrame with the runners times and calculates the best time
    and cumulative best time of all the data, then adds these as new columns
    and returns the modified DataFrame.
    """
    times = times.with_columns(
        pl.struct(times.columns)
        .map_elements(
            function=lambda row: compute_lowest_time(times=list(row.values())),
            return_dtype=pl.String,
        )
        .alias(name="Best"),
    )

    times = times.with_columns(
        pl.col(name="Best")
        .map_elements(
            function=parse_duration,
            return_dtype=pl.Decimal(precision=None, scale=3),
        )
        .alias(name="Best (seconds)"),
    )

    times = times.with_columns(
        pl.col(name="Best (seconds)").cum_sum().alias(name="Cumulative best (seconds)"),
    )

    times = times.with_columns(
        pl.col(name="Cumulative best (seconds)")
        .map_elements(function=format_duration, return_dtype=pl.String)
        .alias(name="Cumulative best"),
    )

    times = times.drop(["Best (seconds)", "Cumulative best (seconds)"])

    # Remove the last row of the Best and Cumulative best columns.
    return times.with_columns(
        pl.when(pl.int_range(0, pl.len()) == pl.len() - 1)
        .then(statement=pl.lit(value=""))
        .otherwise(statement=pl.col(name="Best"))
        .alias(name="Best"),
        pl.when(pl.int_range(0, pl.len()) == pl.len() - 1)
        .then(statement=pl.lit(value=""))
        .otherwise(statement=pl.col(name="Cumulative best"))
        .alias(name="Cumulative best"),
    )


def diff_before_after(df1: DataFrame, df2: DataFrame) -> DataFrame:
    """
    Compares two DataFrames that should have the same exact shape and returns
    a DataFrame with the differences between them (can be an empty DataFrame if
    there are no differences).

    The resulting difference df has three columns:

    - Runner
    - Split Name
    - Before vs. After
    """
    if df1.shape != df2.shape:
        msg = f"DataFrames have different shapes: {df1.shape} vs {df2.shape}"
        raise ValueError(
            msg,
        )

    diffs: list[DataFrame] = []
    for col in df1.columns:
        diff = pl.DataFrame(
            data={
                "Runner": col,
                "Split/Chapter/Area Name": df1.get_column(df1.columns[0]),
                "Before": df1[col],
                "After": df2[col],
            },
        ).filter(pl.col(name="Before").ne_missing(other=pl.col(name="After")))
        diff = diff.with_columns(
            (
                pl.col(name="Before").map_elements(
                    function=parse_duration,
                    return_dtype=pl.Decimal(precision=10, scale=3),
                )
                - pl.col(name="After").map_elements(
                    function=parse_duration,
                    return_dtype=pl.Decimal(precision=10, scale=3),
                )
            )
            .map_elements(function=lambda x: f"{x:.3f}", return_dtype=pl.String)
            .alias(name="Difference"),
        )
        diff = diff.with_columns(
            (
                (pl.col(name="Before") + pl.lit(value=" → ") + pl.col(name="After"))
                + pl.lit(value=" (-")
                + pl.col(name="Difference")
                + pl.lit(value=")")
            ).alias(
                name="Before vs. After",
            ),
        ).drop(["Before", "After", "Difference"])
        diffs.append(diff)

    return (
        pl.concat(items=diffs, how="vertical")
        if diffs
        else DataFrame(
            data=None,
            schema={
                "Runner": pl.Utf8,
                "Split/Chapter/Area Name": pl.Utf8,
                "Before vs. After": pl.Utf8,
            },
        )
    )
