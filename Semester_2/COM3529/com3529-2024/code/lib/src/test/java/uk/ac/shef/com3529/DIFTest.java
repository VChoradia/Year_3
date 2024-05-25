package uk.ac.shef.com3529;

import org.junit.jupiter.api.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.core.IsEqual.equalTo;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static uk.ac.shef.com3529.DIFFixed.*;

public class DIFTest {

    @Test
    public void findLast_failure() {
        int[] arr = {0};
        assertThat(findLast(arr, 0), equalTo(0));
    }

    @Test
    public void findLast_defectNotExecuted() {
        int x[] = {12, 5, 4, 3, 0, 9};
        int y = 0;

        int result = DIF.findLast(x, y);
        assertEquals(y, result);
    }

    @Test
    public void findLast_defectExecuted_noInfection() {
        int x[] = null;
        int y = 7;
        assertThrows(NullPointerException.class, () -> {
            int result = DIF.findLast(x, y);
        });
    }

    @Test
    public void findLast_defectExecuted_noInfection() {
        int[] arr = {0, 1};
        assertThat(findLast(arr, 1), equalTo(1));
    }

    @Test
    public void countPositive_failure() {
        int[] arr = {0};
        assertThat(countPositive(arr), equalTo(0));
    }

    @Test
    public void countPositive_defectNotExecuted() {
        int[] arr = {};
        assertThat(countPositive(arr), equalTo(0));
    }

    @Test
    public void countPositive_defectExecuted_noInfection() {
        int[] arr = {1};
        assertThat(countPositive(arr), equalTo(1));
    }

    @Test
    public void lastZero_failure() {
        int[] arr = {0, 0};
        assertThat(lastZero_fix1(arr), equalTo(1));
    }

    @Test
    public void lastZero_defectNotExecuted() {
        assertThrows(NullPointerException.class, () -> {
            lastZero_fix1(null);
        });
    }

    @Test
    public void lastZero_defectExecuted_noInfection() {
        int[] arr = {1};
        assertThat(lastZero_fix1(arr), equalTo(-1));
    }

    @Test
    public void lastZero_defectExecuted_infectionCaused_noFailure() {
        int[] arr = {0, 1};
        assertThat(lastZero_fix1(arr), equalTo(0));
    }

    @Test
    public void oddOrPos_failure() {
        int[] arr = {-1};
        assertThat(oddOrPos(arr), equalTo(1));
    }

    @Test
    public void oddOrPoss_defectNotExecuted() {
        int[] arr = {};
        assertThat(oddOrPos(arr), equalTo(0));
    }

    @Test
    public void oddOrPos_defectExecuted_noInfection() {
        int[] arr = {1};
        assertThat(oddOrPos(arr), equalTo(1));
    }
}
