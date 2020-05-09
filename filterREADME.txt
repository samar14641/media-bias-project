All filters are in the filters directory.

Individual filters are written in newsSiteNameFilter.R, and have all been combined in combinedFilter.R to produce the final dataset.

All filters check if article text exists (!is.na(article_text)), and then keep articles after 1st August 2019.
NOTE: DATE FORMAT BEING USED IS yyyy-mm-dd

Dataset sources:
1. BBC: Connor
2. Breitbart: Oliver
3. BuzzFeed: Oliver (not currently in the dataset)
4. CNN: Connor
5. Five Thiry Eight: Connor
6. Fox: Connor
7. Mother Jones: Connor
8. Reuters: Connor
9. Vox: Oliver