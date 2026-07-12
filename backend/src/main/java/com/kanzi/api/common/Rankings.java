package com.kanzi.api.common;

import java.util.List;
import java.util.function.BiPredicate;

/** The app's ranking convention, in one place. */
public final class Rankings {

    private Rankings() {
    }

    /**
     * Competition ranking (1, 2, 2, 4) over an already-sorted list: element {@code i} gets rank
     * {@code i + 1} unless {@code ties} says it ties the previous element, in which case it
     * shares that element's rank.
     */
    public static <T> int[] competitionRanks(List<T> sorted, BiPredicate<T, T> ties) {
        int[] ranks = new int[sorted.size()];
        for (int i = 0; i < sorted.size(); i++) {
            ranks[i] = (i > 0 && ties.test(sorted.get(i), sorted.get(i - 1))) ? ranks[i - 1] : i + 1;
        }
        return ranks;
    }
}
