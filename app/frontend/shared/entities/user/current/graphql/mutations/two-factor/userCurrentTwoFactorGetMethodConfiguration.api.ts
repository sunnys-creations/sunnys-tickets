import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTwoFactorGetMethodConfigurationDocument = gql`
    query userCurrentTwoFactorGetMethodConfiguration($methodName: String!, $token: String!) {
  userCurrentTwoFactorGetMethodConfiguration(
    methodName: $methodName
    token: $token
  )
}
    `;
export function useUserCurrentTwoFactorGetMethodConfigurationQuery(variables: Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables | VueCompositionApi.Ref<Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables> | ReactiveFunction<Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>(UserCurrentTwoFactorGetMethodConfigurationDocument, variables, options);
}
export function useUserCurrentTwoFactorGetMethodConfigurationLazyQuery(variables?: Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables | VueCompositionApi.Ref<Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables> | ReactiveFunction<Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>(UserCurrentTwoFactorGetMethodConfigurationDocument, variables, options);
}
export type UserCurrentTwoFactorGetMethodConfigurationQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>;