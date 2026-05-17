class VerticalDatabase:
    def __init__(self):
        self.item_tidsets = {}
        self.num_transactions = 0

    def build_from_horizontal(self, data):
        self.num_transactions = len(data)
        for tid, transaction in enumerate(data):
            for item in transaction:
                if item not in self.item_tidsets:
                    self.item_tidsets[item] = 0
                self.item_tidsets[item] |= (1 << tid)