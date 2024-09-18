# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Styler.Config do
  @moduledoc false
  @key __MODULE__

  @stdlib MapSet.new(~w(
    Access Agent Application Atom Base Behaviour Bitwise Code Date DateTime Dict Ecto Enum Exception
    File Float GenEvent GenServer HashDict HashSet Integer IO Kernel Keyword List
    Macro Map MapSet Module NaiveDateTime Node Oban OptionParser Path Port Process Protocol
    Range Record Regex Registry Set Stream String StringIO Supervisor System Task Time Tuple URI Version
  )a)

  @styles [
    Styler.Style.ModuleDirectives,
    Styler.Style.Pipes,
    Styler.Style.SingleNode,
    Styler.Style.Defs,
    Styler.Style.Blocks,
    Styler.Style.Deprecations,
    Styler.Style.Configs
  ]

  def set(config) do
    :persistent_term.get(@key)
    :ok
  rescue
    ArgumentError -> set!(config)
  end

  def set!(config) do
    excludes =
      config[:alias_lifting_exclude]
      |> List.wrap()
      |> MapSet.new(fn
        atom when is_atom(atom) ->
          case to_string(atom) do
            "Elixir." <> rest -> String.to_atom(rest)
            _ -> atom
          end

        other ->
          raise "Expected an atom for `alias_lifting_exclude`, got: #{inspect(other)}"
      end)
      |> MapSet.union(@stdlib)

    zero_arity_parens = config[:zero_arity_parens]
    sort_order = config[:sort_order] || :alpha
    reorder_configs = if is_nil(config[:reorder_configs]), do: true, else: config[:reorder_configs]
    rewrite_case_to_if = if is_nil(config[:rewrite_case_to_if]), do: true, else: config[:rewrite_case_to_if]
    rewrite_if_to_unless = config[:rewrite_if_to_unless] || false

    :persistent_term.put(@key, %{
      rewrite_case_to_if: rewrite_case_to_if,
      lifting_excludes: excludes,
      reorder_configs: reorder_configs,
      rewrite_if_to_unless: rewrite_if_to_unless,
      sort_order: sort_order,
      zero_arity_parens: zero_arity_parens
    })
  end

  def get(key) do
    @key
    |> :persistent_term.get()
    |> Map.fetch!(key)
  end

  def zero_arity_parens? do
    get(:zero_arity_parens)
  end

  def sort_order do
    get(:sort_order)
  end

  def rewrite_case_to_if? do
    get(:rewrite_case_to_if)
  end

  def rewrite_if_to_unless? do
    get(:rewrite_if_to_unless)
  end

  def get_styles do
    maybe_exclude(@styles, Styler.Style.Configs, get(:reorder_configs))
  end

  defp maybe_exclude(list, _elem, true), do: list
  defp maybe_exclude(list, elem, false), do: list -- [elem]
end
