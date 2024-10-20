# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Quokka.Style.StylesTest do
  @moduledoc """
  A place for tests that make sure our styles play nicely with each other
  """
  use Quokka.StyleCase, async: true

  describe "pipes + defs" do
    test "pipes doesnt abuse meta and break defs" do
      Quokka.Config.set_for_test!(:single_pipe_flag, true)
      assert_style(
        """
        foo
        |> bar(fn baz ->
          def widget do
            :bop
          end
        end)
        """,
        """
        bar(foo, fn baz ->
          def widget() do
            :bop
          end
        end)
        """
      )

      Quokka.Config.set_for_test!(:single_pipe_flag, false)
    end
  end
end
