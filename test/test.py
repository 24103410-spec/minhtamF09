import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def test_f09(dut):
    dut.ena.value = 1
    dut.uio_in.value = 0
    dut.ui_in.value = 0
    dut.rst_n.value = 0
    dut.clk.value = 0

    position = 0
    previous = 0

    # State encoding: AB = 00, 01, 11, 10.
    # ui_in[0] = A; ui_in[1] = B.
    clockwise = {(0, 1), (1, 3), (3, 2), (2, 0)}
    counterclockwise = {(0, 2), (2, 3), (3, 1), (1, 0)}

    async def step(state, reset=False):
        nonlocal position, previous

        dut.clk.value = 0
        a = (state >> 1) & 1
        b = state & 1
        dut.ui_in.value = a | (b << 1)
        dut.rst_n.value = 0 if reset else 1

        await Timer(50, unit="ns")
        dut.clk.value = 1
        await Timer(50, unit="ns")

        flags = 0
        if reset:
            position = 0
            previous = 0
        else:
            transition = (previous, state)
            if transition in clockwise:
                position = (position + 1) & 255
                flags = 1
            elif transition in counterclockwise:
                position = (position - 1) & 255
                flags = 2
            elif previous != state:
                flags = 4
            previous = state

        actual_position = int(dut.uo_out.value)
        actual_flags = int(dut.uio_out.value)

        assert actual_position == position, (
            f"Position: expected {position}, got {actual_position}"
        )
        assert actual_flags == flags, (
            f"Flags: expected {flags}, got {actual_flags}"
        )
        assert int(dut.uio_oe.value) == 7, "Incorrect output enables"

    # Reset and stationary input.
    await step(0, reset=True)
    await step(0)
    await step(0)

    # 260 clockwise transitions: includes overflow 255 -> 0.
    for _ in range(65):
        for state in (1, 3, 2, 0):
            await step(state)
    assert position == 4

    # Reset, then 260 counterclockwise transitions:
    # includes underflow 0 -> 255.
    await step(0, reset=True)
    for _ in range(65):
        for state in (2, 3, 1, 0):
            await step(state)
    assert position == 252

    # Check all 16 previous/current state combinations.
    for start in range(4):
        for finish in range(4):
            await step(0, reset=True)
            await step(start)
            await step(finish)
            # Hold state: event outputs must clear.
            await step(finish)

    # Reset must clear an existing nonzero count.
    await step(0, reset=True)
    await step(1)
    assert position == 1
    await step(0, reset=True)

    dut._log.info("F09: all encoder tests passed")
